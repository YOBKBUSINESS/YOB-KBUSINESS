import 'package:postgres/postgres.dart';
import '../db/database.dart';

class BoreholeRepository {
  final Database _db;

  BoreholeRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause +=
          " AND (name ILIKE @search OR location ILIKE @search OR contractor ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (status != null && status.isNotEmpty) {
      whereClause += " AND status = @status::project_status";
      params['status'] = status;
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM boreholes $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named(
        'SELECT * FROM boreholes $whereClause ORDER BY created_at DESC LIMIT @limit OFFSET @offset',
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

  Future<Map<String, dynamic>?> findById(String id) async {
    final result = await _conn.execute(
      Sql.named('SELECT * FROM boreholes WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO boreholes (name, location, cost, contractor, start_date, end_date,
          progress_percent, status, photo_urls, maintenance_notes, last_maintenance_date)
        VALUES (@name, @location, @cost, @contractor, @start_date, @end_date,
          @progress_percent, @status::project_status, @photo_urls, @maintenance_notes, @last_maintenance_date)
        RETURNING *
      '''),
      parameters: {
        'name': data['name'],
        'location': data['location'],
        'cost': data['cost'] ?? 0,
        'contractor': data['contractor'],
        'start_date': data['start_date'],
        'end_date': data['end_date'],
        'progress_percent': data['progress_percent'] ?? 0,
        'status': data['status'] ?? 'planned',
        'photo_urls': data['photo_urls'] ?? <String>[],
        'maintenance_notes': data['maintenance_notes'],
        'last_maintenance_date': data['last_maintenance_date'],
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE boreholes SET
          name = COALESCE(@name, name),
          location = COALESCE(@location, location),
          cost = COALESCE(@cost, cost),
          contractor = COALESCE(@contractor, contractor),
          start_date = COALESCE(@start_date, start_date),
          end_date = COALESCE(@end_date, end_date),
          progress_percent = COALESCE(@progress_percent, progress_percent),
          status = COALESCE(@status::project_status, status),
          photo_urls = COALESCE(@photo_urls, photo_urls),
          maintenance_notes = COALESCE(@maintenance_notes, maintenance_notes),
          last_maintenance_date = COALESCE(@last_maintenance_date, last_maintenance_date)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'name': data['name'],
        'location': data['location'],
        'cost': data['cost'],
        'contractor': data['contractor'],
        'start_date': data['start_date'],
        'end_date': data['end_date'],
        'progress_percent': data['progress_percent'],
        'status': data['status'],
        'photo_urls': data['photo_urls'],
        'maintenance_notes': data['maintenance_notes'],
        'last_maintenance_date': data['last_maintenance_date'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM boreholes WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'name': row['name'],
      'location': row['location'],
      'cost': (row['cost'] as num?)?.toDouble() ?? 0,
      'contractor': row['contractor'],
      'startDate': row['start_date']?.toString(),
      'endDate': row['end_date']?.toString(),
      'progressPercent': row['progress_percent'] ?? 0,
      'status': row['status']?.toString() ?? 'planned',
      'photoUrls': row['photo_urls'] is List
          ? (row['photo_urls'] as List).cast<String>()
          : <String>[],
      'maintenanceNotes': row['maintenance_notes'],
      'lastMaintenanceDate': row['last_maintenance_date']?.toString(),
      'createdAt': row['created_at']?.toString(),
      'updatedAt': row['updated_at']?.toString(),
    };
  }
}
