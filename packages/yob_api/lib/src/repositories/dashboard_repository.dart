import 'package:postgres/postgres.dart';
import '../db/database.dart';

/// Aggregated KPIs for the Director General dashboard.
class DashboardRepository {
  final Database _db;

  DashboardRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  /// Core KPI stats.
  Future<Map<String, dynamic>> getKpis() async {
    // Producers
    final prodResult = await _conn.execute(Sql.named('''
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'actif') as active
      FROM producers
    '''));
    final prodRow = prodResult.first.toColumnMap();

    // Parcels — total hectares
    final parcelResult = await _conn.execute(Sql.named(
      'SELECT COALESCE(SUM(surface_area), 0) as total_ha FROM parcels',
    ));
    final totalHa = _toDouble(
      parcelResult.first.toColumnMap()['total_ha'],
    );

    // Estimated production (sum of production_level across active producers)
    final estResult = await _conn.execute(Sql.named('''
      SELECT COALESCE(SUM(production_level), 0) as est
      FROM producers
      WHERE status = 'actif'
    '''));
    final estProduction = _toDouble(
      estResult.first.toColumnMap()['est'],
    );

    // Treasury balance
    final treasuryResult = await _conn.execute(Sql.named('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0)
          - COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
          as balance
      FROM transactions
    '''));
    final balance = _toDouble(
      treasuryResult.first.toColumnMap()['balance'],
    );

    // Active projects (boreholes in progress)
    final projResult = await _conn.execute(Sql.named('''
      SELECT COUNT(*) as count
      FROM boreholes
      WHERE status IN ('inProgress', 'planned')
    '''));
    final activeProjects = projResult.first.toColumnMap()['count'] as int;

    // Investor count + total invested
    final invResult = await _conn.execute(Sql.named('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(total_invested), 0) as invested
      FROM investors
    '''));
    final invRow = invResult.first.toColumnMap();

    return {
      'totalProducers': prodRow['total'] as int,
      'activeProducers': prodRow['active'] as int,
      'totalHectares': totalHa,
      'estimatedProduction': estProduction,
      'availableCash': balance,
      'activeProjects': activeProjects,
      'investorCount': invRow['count'] as int,
      'totalInvested': _toDouble(invRow['invested']),
    };
  }

  /// Urgent alerts.
  Future<List<Map<String, dynamic>>> getAlerts() async {
    final alerts = <Map<String, dynamic>>[];

    // 1. Low treasury alert
    final treasuryResult = await _conn.execute(Sql.named('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0)
          - COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
          as balance
      FROM transactions
    '''));
    final balance = _toDouble(
      treasuryResult.first.toColumnMap()['balance'],
    );
    if (balance < 500000) {
      alerts.add({
        'id': 'treasury-low',
        'title': 'Trésorerie basse',
        'message': balance < 0
            ? 'Trésorerie négative: ${_formatFcfa(balance)}'
            : 'Solde de ${_formatFcfa(balance)} (seuil: 500 000 FCFA)',
        'severity': balance < 0 ? 'critical' : 'warning',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // 2. Suspended producers
    final suspResult = await _conn.execute(Sql.named(
      "SELECT COUNT(*) as c FROM producers WHERE status = 'suspendu'",
    ));
    final suspCount = suspResult.first.toColumnMap()['c'] as int;
    if (suspCount > 0) {
      alerts.add({
        'id': 'producers-suspended',
        'title': 'Producteurs suspendus',
        'message': '$suspCount producteur${suspCount > 1 ? 's' : ''} '
            'suspendu${suspCount > 1 ? 's' : ''}',
        'severity': 'warning',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // 3. Overdue boreholes (past end_date but not completed)
    final overdueResult = await _conn.execute(Sql.named('''
      SELECT COUNT(*) as c FROM boreholes
      WHERE end_date < NOW()::date
        AND status NOT IN ('completed')
    '''));
    final overdueCount = overdueResult.first.toColumnMap()['c'] as int;
    if (overdueCount > 0) {
      alerts.add({
        'id': 'boreholes-overdue',
        'title': 'Forages en retard',
        'message': '$overdueCount forage${overdueCount > 1 ? 's' : ''} '
            'dépassant la date de fin prévue',
        'severity': 'warning',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // 4. Kits not repaid
    final kitsResult = await _conn.execute(Sql.named('''
      SELECT COUNT(*) as c, COALESCE(SUM(value), 0) as total
      FROM agricultural_kits
      WHERE status = 'subventionne'
    '''));
    final kitsRow = kitsResult.first.toColumnMap();
    final kitsCount = kitsRow['c'] as int;
    final kitsValue = _toDouble(kitsRow['total']);
    if (kitsCount > 5 && kitsValue > 1000000) {
      alerts.add({
        'id': 'kits-pending',
        'title': 'Kits non remboursés',
        'message': '$kitsCount kits subventionnés '
            '(${_formatFcfa(kitsValue)})',
        'severity': 'info',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return alerts;
  }

  /// Active projects overview (boreholes in progress / planned).
  Future<List<Map<String, dynamic>>> getActiveProjects() async {
    final result = await _conn.execute(Sql.named('''
      SELECT id, name, location, cost, contractor,
             start_date, end_date, progress_percent, status
      FROM boreholes
      WHERE status IN ('inProgress', 'planned')
      ORDER BY
        CASE WHEN status = 'inProgress' THEN 0 ELSE 1 END,
        start_date DESC
      LIMIT 20
    '''));

    return result.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'].toString(),
        'name': row['name'] as String,
        'location': row['location'] as String,
        'cost': _toDouble(row['cost']),
        'contractor': row['contractor'] as String,
        'startDate': (row['start_date'] is DateTime)
            ? (row['start_date'] as DateTime).toIso8601String()
            : row['start_date']?.toString(),
        'endDate': row['end_date'] != null
            ? (row['end_date'] is DateTime
                ? (row['end_date'] as DateTime).toIso8601String()
                : row['end_date']?.toString())
            : null,
        'progress': row['progress_percent'] as int,
        'status': row['status'].toString(),
      };
    }).toList();
  }

  /// Module-level summary counts for quick overview.
  Future<Map<String, dynamic>> getModuleSummary() async {
    final results = await Future.wait([
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM producers')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM parcels')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM boreholes')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM agricultural_kits')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM trainings')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM transactions')),
      _conn.execute(Sql.named('SELECT COUNT(*) as c FROM investors')),
    ]);

    return {
      'producers': results[0].first.toColumnMap()['c'] as int,
      'parcels': results[1].first.toColumnMap()['c'] as int,
      'boreholes': results[2].first.toColumnMap()['c'] as int,
      'kits': results[3].first.toColumnMap()['c'] as int,
      'trainings': results[4].first.toColumnMap()['c'] as int,
      'transactions': results[5].first.toColumnMap()['c'] as int,
      'investors': results[6].first.toColumnMap()['c'] as int,
    };
  }

  /// Recent activity feed (last 15 transactions).
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final result = await _conn.execute(Sql.named('''
      SELECT t.id, t.type::text as type, t.amount, t.description,
             t.category, t.date, u.full_name as created_by_name
      FROM transactions t
      LEFT JOIN users u ON t.created_by = u.id
      ORDER BY t.date DESC, t.created_at DESC
      LIMIT 15
    '''));

    return result.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'].toString(),
        'type': row['type'] as String,
        'amount': _toDouble(row['amount']),
        'description': row['description'] as String? ?? '',
        'category': row['category'] as String?,
        'date': (row['date'] is DateTime)
            ? (row['date'] as DateTime).toIso8601String()
            : row['date']?.toString(),
        'createdByName': row['created_by_name'] as String?,
      };
    }).toList();
  }

  // ── Helpers ──

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatFcfa(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted FCFA';
  }
}
