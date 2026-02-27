import 'package:postgres/postgres.dart';
import '../db/database.dart';

class KitRepository {
  final Database _db;

  KitRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? beneficiaryId,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause +=
          " AND (k.kit_type ILIKE @search OR pr.full_name ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (status != null && status.isNotEmpty) {
      whereClause += " AND k.status = @status::kit_status";
      params['status'] = status;
    }
    if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
      whereClause += " AND k.beneficiary_id = @beneficiary_id";
      params['beneficiary_id'] = beneficiaryId;
    }

    final countResult = await _conn.execute(
      Sql.named('''
        SELECT COUNT(*) as total
        FROM agricultural_kits k
        LEFT JOIN producers pr ON k.beneficiary_id = pr.id
        $whereClause
      '''),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named('''
        SELECT k.*, pr.full_name AS beneficiary_name
        FROM agricultural_kits k
        LEFT JOIN producers pr ON k.beneficiary_id = pr.id
        $whereClause
        ORDER BY k.distribution_date DESC LIMIT @limit OFFSET @offset
      '''),
      parameters: params,
    );

    return {
      'items': result.map((r) => _rowToMap(r.toColumnMap())).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': (total / limit).ceil(),
    };
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('''
        SELECT k.*, pr.full_name AS beneficiary_name
        FROM agricultural_kits k
        LEFT JOIN producers pr ON k.beneficiary_id = pr.id
        WHERE k.id = @id
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO agricultural_kits (kit_type, distribution_date, beneficiary_id, value, status)
        VALUES (@kit_type, @distribution_date, @beneficiary_id, @value, @status::kit_status)
        RETURNING *
      '''),
      parameters: {
        'kit_type': data['kit_type'],
        'distribution_date': data['distribution_date'],
        'beneficiary_id': data['beneficiary_id'],
        'value': data['value'] ?? 0,
        'status': data['status'] ?? 'subventionne',
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE agricultural_kits SET
          kit_type = COALESCE(@kit_type, kit_type),
          distribution_date = COALESCE(@distribution_date, distribution_date),
          beneficiary_id = COALESCE(@beneficiary_id, beneficiary_id),
          value = COALESCE(@value, value),
          status = COALESCE(@status::kit_status, status)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'kit_type': data['kit_type'],
        'distribution_date': data['distribution_date'],
        'beneficiary_id': data['beneficiary_id'],
        'value': data['value'],
        'status': data['status'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM agricultural_kits WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  /// Get kits for a specific producer.
  Future<List<Map<String, dynamic>>> findByBeneficiary(
      String producerId) async {
    final result = await _conn.execute(
      Sql.named(
          'SELECT * FROM agricultural_kits WHERE beneficiary_id = @pid ORDER BY distribution_date DESC'),
      parameters: {'pid': producerId},
    );
    return result.map((r) => _rowToMap(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'kitType': row['kit_type'],
      'distributionDate': row['distribution_date']?.toString(),
      'beneficiaryId': row['beneficiary_id']?.toString(),
      'beneficiaryName': row['beneficiary_name'],
      'value': (row['value'] as num?)?.toDouble() ?? 0,
      'status': row['status']?.toString() ?? 'subventionne',
      'createdAt': row['created_at']?.toString(),
      'updatedAt': row['updated_at']?.toString(),
    };
  }
}
