import 'package:postgres/postgres.dart';
import '../db/database.dart';

class TransactionRepository {
  final Database _db;

  TransactionRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  /// List transactions with filters & pagination.
  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? type, // income | expense
    String? category,
    String? dateFrom,
    String? dateTo,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause +=
          " AND (description ILIKE @search OR category ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (type != null && type.isNotEmpty) {
      whereClause += " AND type = @type::transaction_type";
      params['type'] = type;
    }
    if (category != null && category.isNotEmpty) {
      whereClause += " AND category = @category";
      params['category'] = category;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      whereClause += " AND date >= @date_from::date";
      params['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      whereClause += " AND date <= @date_to::date";
      params['date_to'] = dateTo;
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM transactions $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named('''
        SELECT t.*, u.full_name as created_by_name
        FROM transactions t
        LEFT JOIN users u ON t.created_by = u.id
        $whereClause
        ORDER BY t.date DESC, t.created_at DESC
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

  /// Get a single transaction.
  Future<Map<String, dynamic>?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT t.*, u.full_name as created_by_name
        FROM transactions t
        LEFT JOIN users u ON t.created_by = u.id
        WHERE t.id = @id
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  /// Create a transaction.
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO transactions (type, amount, description, category, reference_id, date, created_by)
        VALUES (@type::transaction_type, @amount, @description, @category, @reference_id, @date::date, @created_by)
        RETURNING *
      '''),
      parameters: {
        'type': data['type'],
        'amount': data['amount'],
        'description': data['description'],
        'category': data['category'],
        'reference_id': data['referenceId'],
        'date': data['date'],
        'created_by': data['createdBy'],
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  /// Update a transaction.
  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE transactions SET
          type = COALESCE(@type::transaction_type, type),
          amount = COALESCE(@amount, amount),
          description = COALESCE(@description, description),
          category = COALESCE(@category, category),
          reference_id = COALESCE(@reference_id, reference_id),
          date = COALESCE(@date::date, date)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'type': data['type'],
        'amount': data['amount'],
        'description': data['description'],
        'category': data['category'],
        'reference_id': data['referenceId'],
        'date': data['date'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  /// Delete a transaction.
  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM transactions WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// Calculate treasury: total income - total expense.
  Future<Map<String, dynamic>> getTreasury() async {
    final result = await _conn.execute(Sql.named('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense
      FROM transactions
    '''));
    final row = result.first.toColumnMap();
    final totalIncome = _toDouble(row['total_income']);
    final totalExpense = _toDouble(row['total_expense']);

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  /// Get monthly summary for a given year.
  Future<List<Map<String, dynamic>>> getMonthlySummary(int year) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT
          EXTRACT(MONTH FROM date)::int as month,
          type::text as type,
          SUM(amount) as total
        FROM transactions
        WHERE EXTRACT(YEAR FROM date) = @year
        GROUP BY month, type
        ORDER BY month
      '''),
      parameters: {'year': year},
    );

    // Build 12-month array
    final months = List.generate(12, (i) => {
      'month': i + 1,
      'income': 0.0,
      'expense': 0.0,
    });

    for (final r in result) {
      final row = r.toColumnMap();
      final m = (row['month'] as int) - 1;
      final type = row['type'] as String;
      final total = _toDouble(row['total']);
      if (type == 'income') {
        months[m]['income'] = total;
      } else {
        months[m]['expense'] = total;
      }
    }

    return months;
  }

  /// Get breakdown by category for a time range.
  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required String type, // income | expense
    String? dateFrom,
    String? dateTo,
  }) async {
    var whereClause = "WHERE type = @type::transaction_type";
    final params = <String, dynamic>{'type': type};

    if (dateFrom != null && dateFrom.isNotEmpty) {
      whereClause += " AND date >= @date_from::date";
      params['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      whereClause += " AND date <= @date_to::date";
      params['date_to'] = dateTo;
    }

    final result = await _conn.execute(
      Sql.named('''
        SELECT category, SUM(amount) as total, COUNT(*) as count
        FROM transactions
        $whereClause
        GROUP BY category
        ORDER BY total DESC
      '''),
      parameters: params,
    );

    return result.map((r) {
      final row = r.toColumnMap();
      return {
        'category': row['category'] ?? 'Non catégorisé',
        'total': _toDouble(row['total']),
        'count': row['count'] as int,
      };
    }).toList();
  }

  /// Get recent transactions (for dashboard).
  Future<List<Map<String, dynamic>>> getRecent({int limit = 10}) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT t.*, u.full_name as created_by_name
        FROM transactions t
        LEFT JOIN users u ON t.created_by = u.id
        ORDER BY t.date DESC, t.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );
    return result.map((r) => _rowToMap(r.toColumnMap())).toList();
  }

  /// Check if treasury is below alert threshold.
  Future<Map<String, dynamic>> checkAlert({double threshold = 500000}) async {
    final treasury = await getTreasury();
    final balance = treasury['balance'] as double;
    return {
      ...treasury,
      'threshold': threshold,
      'isLow': balance < threshold,
      'alertLevel': balance < 0
          ? 'critical'
          : balance < threshold
              ? 'warning'
              : 'ok',
    };
  }

  /// Monthly report data for a given month/year.
  Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    final params = <String, dynamic>{'year': year, 'month': month};

    // Totals
    final totals = await _conn.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense,
          COUNT(*) as tx_count
        FROM transactions
        WHERE EXTRACT(YEAR FROM date) = @year AND EXTRACT(MONTH FROM date) = @month
      '''),
      parameters: params,
    );
    final totRow = totals.first.toColumnMap();

    // Category breakdown
    final cats = await _conn.execute(
      Sql.named('''
        SELECT type::text, category, SUM(amount) as total
        FROM transactions
        WHERE EXTRACT(YEAR FROM date) = @year AND EXTRACT(MONTH FROM date) = @month
        GROUP BY type, category
        ORDER BY total DESC
      '''),
      parameters: params,
    );

    // Top transactions
    final topTx = await _conn.execute(
      Sql.named('''
        SELECT t.*, u.full_name as created_by_name
        FROM transactions t
        LEFT JOIN users u ON t.created_by = u.id
        WHERE EXTRACT(YEAR FROM t.date) = @year AND EXTRACT(MONTH FROM t.date) = @month
        ORDER BY t.amount DESC
        LIMIT 10
      '''),
      parameters: params,
    );

    // Overall treasury
    final treasury = await getTreasury();

    return {
      'year': year,
      'month': month,
      'income': _toDouble(totRow['income']),
      'expense': _toDouble(totRow['expense']),
      'net': _toDouble(totRow['income']) - _toDouble(totRow['expense']),
      'transactionCount': totRow['tx_count'] as int,
      'categoryBreakdown': cats.map((r) {
        final row = r.toColumnMap();
        return {
          'type': row['type'],
          'category': row['category'] ?? 'Non catégorisé',
          'total': _toDouble(row['total']),
        };
      }).toList(),
      'topTransactions':
          topTx.map((r) => _rowToMap(r.toColumnMap())).toList(),
      'treasury': treasury,
    };
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
      'type': (row['type'] is String)
          ? row['type']
          : row['type']?.toString() ?? 'income',
      'amount': _toDouble(row['amount']),
      'description': row['description'] as String? ?? '',
      'category': row['category'] as String?,
      'referenceId': row['reference_id']?.toString(),
      'date': (row['date'] is DateTime)
          ? (row['date'] as DateTime).toIso8601String()
          : row['date']?.toString(),
      'createdBy': row['created_by']?.toString(),
      'createdByName': row['created_by_name'] as String?,
      'createdAt': (row['created_at'] is DateTime)
          ? (row['created_at'] as DateTime).toIso8601String()
          : row['created_at']?.toString(),
    };
  }
}
