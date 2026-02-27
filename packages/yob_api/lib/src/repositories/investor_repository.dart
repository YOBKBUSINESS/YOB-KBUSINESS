import 'package:postgres/postgres.dart';
import '../db/database.dart';

class InvestorRepository {
  final Database _db;

  InvestorRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  /// List investors with search & pagination.
  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause +=
          " AND (full_name ILIKE @search OR email ILIKE @search OR company ILIKE @search)";
      params['search'] = '%$search%';
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM investors $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named('''
        SELECT * FROM investors $whereClause
        ORDER BY created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: params,
    );

    return {
      'items': result.map((r) => _rowToMap(r.toColumnMap())).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': total == 0 ? 1 : (total / limit).ceil(),
    };
  }

  /// Get single investor with calculated return info.
  Future<Map<String, dynamic>?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('SELECT * FROM investors WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;

    final investor = _rowToMap(result.first.toColumnMap());

    // Calculate related transactions (investments linked to this investor)
    final txResult = await _conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as returns,
          COUNT(*) as tx_count
        FROM transactions
        WHERE reference_id = @id
      '''),
      parameters: {'id': id},
    );
    final txRow = txResult.first.toColumnMap();
    investor['totalReturns'] = _toDouble(txRow['returns']);
    investor['transactionCount'] = txRow['tx_count'] as int;

    return investor;
  }

  /// Create a new investor.
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO investors (full_name, email, phone, company, total_invested,
          project_id, project_name, expected_return)
        VALUES (@full_name, @email, @phone, @company, @total_invested,
          @project_id, @project_name, @expected_return)
        RETURNING *
      '''),
      parameters: {
        'full_name': data['fullName'],
        'email': data['email'],
        'phone': data['phone'],
        'company': data['company'],
        'total_invested': data['totalInvested'] ?? 0,
        'project_id': data['projectId'],
        'project_name': data['projectName'],
        'expected_return': data['expectedReturn'],
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  /// Update an investor.
  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE investors SET
          full_name = COALESCE(@full_name, full_name),
          email = COALESCE(@email, email),
          phone = COALESCE(@phone, phone),
          company = COALESCE(@company, company),
          total_invested = COALESCE(@total_invested, total_invested),
          project_id = COALESCE(@project_id, project_id),
          project_name = COALESCE(@project_name, project_name),
          expected_return = COALESCE(@expected_return, expected_return),
          updated_at = NOW()
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'full_name': data['fullName'],
        'email': data['email'],
        'phone': data['phone'],
        'company': data['company'],
        'total_invested': data['totalInvested'],
        'project_id': data['projectId'],
        'project_name': data['projectName'],
        'expected_return': data['expectedReturn'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  /// Delete an investor.
  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM investors WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// Get portfolio summary across all investors.
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    final result = await _conn.execute(Sql.named('''
      SELECT
        COUNT(*) as investor_count,
        COALESCE(SUM(total_invested), 0) as total_invested,
        COALESCE(AVG(expected_return), 0) as avg_expected_return,
        COUNT(DISTINCT project_name) as project_count
      FROM investors
    '''));
    final row = result.first.toColumnMap();

    // Calculate actual returns from transactions linked to investors
    final returnResult = await _conn.execute(Sql.named('''
      SELECT COALESCE(SUM(t.amount), 0) as total_returns
      FROM transactions t
      INNER JOIN investors i ON t.reference_id = i.id::text
      WHERE t.type = 'income'
    '''));
    final totalReturns =
        _toDouble(returnResult.first.toColumnMap()['total_returns']);

    return {
      'investorCount': row['investor_count'] as int,
      'totalInvested': _toDouble(row['total_invested']),
      'avgExpectedReturn': _toDouble(row['avg_expected_return']),
      'projectCount': row['project_count'] as int,
      'actualReturns': totalReturns,
    };
  }

  /// Get investors grouped by project.
  Future<List<Map<String, dynamic>>> getByProject() async {
    final result = await _conn.execute(Sql.named('''
      SELECT
        COALESCE(project_name, 'Sans projet') as project,
        COUNT(*) as count,
        SUM(total_invested) as invested,
        AVG(expected_return) as avg_return
      FROM investors
      GROUP BY project_name
      ORDER BY invested DESC
    '''));

    return result.map((r) {
      final row = r.toColumnMap();
      return {
        'project': row['project'] as String,
        'count': row['count'] as int,
        'invested': _toDouble(row['invested']),
        'avgReturn': _toDouble(row['avg_return']),
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

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'fullName': row['full_name'] as String? ?? '',
      'email': row['email'] as String?,
      'phone': row['phone'] as String?,
      'company': row['company'] as String?,
      'totalInvested': _toDouble(row['total_invested']),
      'projectId': row['project_id']?.toString(),
      'projectName': row['project_name'] as String?,
      'expectedReturn': row['expected_return'] != null
          ? _toDouble(row['expected_return'])
          : null,
      'createdAt': (row['created_at'] is DateTime)
          ? (row['created_at'] as DateTime).toIso8601String()
          : row['created_at']?.toString(),
      'updatedAt': (row['updated_at'] is DateTime)
          ? (row['updated_at'] as DateTime).toIso8601String()
          : row['updated_at']?.toString(),
    };
  }
}
