import 'package:postgres/postgres.dart';
import '../db/database.dart';

class ParcelRepository {
  final Database _db;

  ParcelRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    String? cropType,
    String? tenureStatus,
    String? producerId,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause += " AND (p.name ILIKE @search OR p.crop_type ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (cropType != null && cropType.isNotEmpty) {
      whereClause += " AND p.crop_type = @crop_type";
      params['crop_type'] = cropType;
    }
    if (tenureStatus != null && tenureStatus.isNotEmpty) {
      whereClause += " AND p.tenure_status = @tenure_status::land_tenure_status";
      params['tenure_status'] = tenureStatus;
    }
    if (producerId != null && producerId.isNotEmpty) {
      whereClause += " AND p.producer_id = @producer_id";
      params['producer_id'] = producerId;
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM parcels p $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named('''
        SELECT p.*, pr.full_name AS producer_name
        FROM parcels p
        LEFT JOIN producers pr ON p.producer_id = pr.id
        $whereClause
        ORDER BY p.created_at DESC LIMIT @limit OFFSET @offset
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
        SELECT p.*, pr.full_name AS producer_name
        FROM parcels p
        LEFT JOIN producers pr ON p.producer_id = pr.id
        WHERE p.id = @id
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO parcels (name, latitude, longitude, surface_area, crop_type,
          tenure_status, commode_survey_done, document_urls, producer_id)
        VALUES (@name, @latitude, @longitude, @surface_area, @crop_type,
          @tenure_status::land_tenure_status, @commode_survey_done, @document_urls, @producer_id)
        RETURNING *
      '''),
      parameters: {
        'name': data['name'],
        'latitude': data['latitude'] ?? 0,
        'longitude': data['longitude'] ?? 0,
        'surface_area': data['surface_area'] ?? 0,
        'crop_type': data['crop_type'],
        'tenure_status': data['tenure_status'] ?? 'unknown',
        'commode_survey_done': data['commode_survey_done'] ?? false,
        'document_urls': data['document_urls'] ?? <String>[],
        'producer_id': data['producer_id'],
      },
    );
    return _rowToMap(result.first.toColumnMap());
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE parcels SET
          name = COALESCE(@name, name),
          latitude = COALESCE(@latitude, latitude),
          longitude = COALESCE(@longitude, longitude),
          surface_area = COALESCE(@surface_area, surface_area),
          crop_type = COALESCE(@crop_type, crop_type),
          tenure_status = COALESCE(@tenure_status::land_tenure_status, tenure_status),
          commode_survey_done = COALESCE(@commode_survey_done, commode_survey_done),
          document_urls = COALESCE(@document_urls, document_urls),
          producer_id = COALESCE(@producer_id, producer_id)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'name': data['name'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'surface_area': data['surface_area'],
        'crop_type': data['crop_type'],
        'tenure_status': data['tenure_status'],
        'commode_survey_done': data['commode_survey_done'],
        'document_urls': data['document_urls'],
        'producer_id': data['producer_id'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM parcels WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  /// Get parcels by producer.
  Future<List<Map<String, dynamic>>> findByProducer(String producerId) async {
    final result = await _conn.execute(
      Sql.named(
          'SELECT * FROM parcels WHERE producer_id = @pid ORDER BY created_at DESC'),
      parameters: {'pid': producerId},
    );
    return result.map((r) => _rowToMap(r.toColumnMap())).toList();
  }

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'name': row['name'],
      'latitude': (row['latitude'] as num?)?.toDouble() ?? 0,
      'longitude': (row['longitude'] as num?)?.toDouble() ?? 0,
      'surfaceArea': (row['surface_area'] as num?)?.toDouble() ?? 0,
      'cropType': row['crop_type'],
      'tenureStatus': row['tenure_status']?.toString() ?? 'unknown',
      'commodeSurveyDone': row['commode_survey_done'] ?? false,
      'documentUrls': row['document_urls'] is List
          ? (row['document_urls'] as List).cast<String>()
          : <String>[],
      'producerId': row['producer_id']?.toString(),
      'producerName': row['producer_name'],
      'createdAt': row['created_at']?.toString(),
      'updatedAt': row['updated_at']?.toString(),
    };
  }
}
