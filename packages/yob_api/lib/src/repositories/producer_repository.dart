import 'package:postgres/postgres.dart';
import '../db/database.dart';

class ProducerRepository {
  final Database _db;

  ProducerRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  /// List all producers with optional search and pagination.
  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? locality,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause += " AND (full_name ILIKE @search OR phone ILIKE @search OR locality ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (status != null && status.isNotEmpty) {
      whereClause += " AND status = @status::producer_status";
      params['status'] = status;
    }
    if (locality != null && locality.isNotEmpty) {
      whereClause += " AND locality ILIKE @locality";
      params['locality'] = '%$locality%';
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM producers $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named(
        'SELECT * FROM producers $whereClause ORDER BY created_at DESC LIMIT @limit OFFSET @offset',
      ),
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

  /// Get a single producer by ID.
  Future<Map<String, dynamic>?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('SELECT * FROM producers WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  /// Create a new producer.
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO producers (full_name, phone, locality, photo_url, id_document_url,
          cultivated_area, status, crop_history, production_level, total_contributions)
        VALUES (@full_name, @phone, @locality, @photo_url, @id_document_url,
          @cultivated_area, @status::producer_status, @crop_history, @production_level, @total_contributions)
        RETURNING *
      '''),
      parameters: {
        'full_name': data['full_name'],
        'phone': data['phone'],
        'locality': data['locality'],
        'photo_url': data['photo_url'],
        'id_document_url': data['id_document_url'],
        'cultivated_area': data['cultivated_area'] ?? 0,
        'status': data['status'] ?? 'actif',
        'crop_history': data['crop_history'] ?? <String>[],
        'production_level': data['production_level'],
        'total_contributions': data['total_contributions'] ?? 0,
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  /// Update a producer.
  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE producers SET
          full_name = COALESCE(@full_name, full_name),
          phone = COALESCE(@phone, phone),
          locality = COALESCE(@locality, locality),
          photo_url = COALESCE(@photo_url, photo_url),
          id_document_url = COALESCE(@id_document_url, id_document_url),
          cultivated_area = COALESCE(@cultivated_area, cultivated_area),
          status = COALESCE(@status::producer_status, status),
          crop_history = COALESCE(@crop_history, crop_history),
          production_level = COALESCE(@production_level, production_level),
          total_contributions = COALESCE(@total_contributions, total_contributions)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'full_name': data['full_name'],
        'phone': data['phone'],
        'locality': data['locality'],
        'photo_url': data['photo_url'],
        'id_document_url': data['id_document_url'],
        'cultivated_area': data['cultivated_area'],
        'status': data['status'],
        'crop_history': data['crop_history'],
        'production_level': data['production_level'],
        'total_contributions': data['total_contributions'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  /// Delete a producer.
  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM producers WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  /// Get stats: count by status.
  Future<Map<String, int>> getStatsByStatus() async {
    final result = await _conn.execute(
      Sql.named(
          'SELECT status, COUNT(*) as count FROM producers GROUP BY status'),
    );
    final stats = <String, int>{};
    for (final row in result) {
      final map = row.toColumnMap();
      stats[map['status'] as String] = map['count'] as int;
    }
    return stats;
  }

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'fullName': row['full_name'],
      'phone': row['phone'],
      'locality': row['locality'],
      'photoUrl': row['photo_url'],
      'idDocumentUrl': row['id_document_url'],
      'cultivatedArea': (row['cultivated_area'] as num?)?.toDouble() ?? 0,
      'status': row['status']?.toString() ?? 'actif',
      'cropHistory': row['crop_history'] is List
          ? (row['crop_history'] as List).cast<String>()
          : <String>[],
      'productionLevel': (row['production_level'] as num?)?.toDouble(),
      'totalContributions':
          (row['total_contributions'] as num?)?.toDouble() ?? 0,
      'createdAt': row['created_at']?.toString(),
      'updatedAt': row['updated_at']?.toString(),
    };
  }
}
