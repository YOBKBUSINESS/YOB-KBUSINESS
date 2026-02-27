import 'package:postgres/postgres.dart';
import '../db/database.dart';

class TrainingRepository {
  final Database _db;

  TrainingRepository({required Database db}) : _db = db;

  Connection get _conn => _db.connection;

  Future<Map<String, dynamic>> findAll({
    int page = 1,
    int limit = 20,
    String? search,
    bool? certificationIssued,
  }) async {
    final offset = (page - 1) * limit;
    var whereClause = 'WHERE 1=1';
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.isNotEmpty) {
      whereClause +=
          " AND (t.title ILIKE @search OR t.location ILIKE @search OR t.description ILIKE @search)";
      params['search'] = '%$search%';
    }
    if (certificationIssued != null) {
      whereClause += " AND t.certification_issued = @cert";
      params['cert'] = certificationIssued;
    }

    final countResult = await _conn.execute(
      Sql.named('SELECT COUNT(*) as total FROM trainings t $whereClause'),
      parameters: params,
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    final result = await _conn.execute(
      Sql.named('''
        SELECT t.*,
          (SELECT COUNT(*) FROM training_attendees ta WHERE ta.training_id = t.id) AS attendee_count
        FROM trainings t
        $whereClause
        ORDER BY t.date DESC LIMIT @limit OFFSET @offset
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
        SELECT t.*,
          (SELECT COUNT(*) FROM training_attendees ta WHERE ta.training_id = t.id) AS attendee_count
        FROM trainings t
        WHERE t.id = @id
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;

    final training = _rowToMap(result.first.toColumnMap());

    // Get attendees
    final attendees = await _conn.execute(
      Sql.named('''
        SELECT ta.*, p.full_name AS producer_name, p.phone AS producer_phone
        FROM training_attendees ta
        JOIN producers p ON ta.producer_id = p.id
        WHERE ta.training_id = @id
      '''),
      parameters: {'id': id},
    );

    training['attendees'] = attendees.map((r) {
      final m = r.toColumnMap();
      return {
        'producerId': m['producer_id']?.toString(),
        'producerName': m['producer_name'],
        'producerPhone': m['producer_phone'],
        'attended': m['attended'] ?? false,
      };
    }).toList();

    return training;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        INSERT INTO trainings (title, description, date, location,
          evaluation_notes, certification_issued)
        VALUES (@title, @description, @date, @location,
          @evaluation_notes, @certification_issued)
        RETURNING *
      '''),
      parameters: {
        'title': data['title'],
        'description': data['description'],
        'date': data['date'],
        'location': data['location'],
        'evaluation_notes': data['evaluation_notes'],
        'certification_issued': data['certification_issued'] ?? false,
      },
    );
    final training = _rowToMap(result.first.toColumnMap());

    // Add attendees if provided
    final attendeeIds = data['attendee_ids'] as List<dynamic>?;
    if (attendeeIds != null && attendeeIds.isNotEmpty) {
      for (final pid in attendeeIds) {
        await _conn.execute(
          Sql.named('''
            INSERT INTO training_attendees (training_id, producer_id, attended)
            VALUES (@tid, @pid, false)
            ON CONFLICT DO NOTHING
          '''),
          parameters: {'tid': training['id'], 'pid': pid},
        );
      }
    }

    return training;
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final result = await _conn.execute(
      Sql.named('''
        UPDATE trainings SET
          title = COALESCE(@title, title),
          description = COALESCE(@description, description),
          date = COALESCE(@date, date),
          location = COALESCE(@location, location),
          evaluation_notes = COALESCE(@evaluation_notes, evaluation_notes),
          certification_issued = COALESCE(@certification_issued, certification_issued)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'title': data['title'],
        'description': data['description'],
        'date': data['date'],
        'location': data['location'],
        'evaluation_notes': data['evaluation_notes'],
        'certification_issued': data['certification_issued'],
      },
    );
    if (result.isEmpty) return null;
    return _rowToMap(result.first.toColumnMap());
  }

  Future<bool> delete(String id) async {
    final result = await _conn.execute(
      Sql.named('DELETE FROM trainings WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  /// Add a producer to a training.
  Future<void> addAttendee(String trainingId, String producerId) async {
    await _conn.execute(
      Sql.named('''
        INSERT INTO training_attendees (training_id, producer_id, attended)
        VALUES (@tid, @pid, false)
        ON CONFLICT DO NOTHING
      '''),
      parameters: {'tid': trainingId, 'pid': producerId},
    );
  }

  /// Remove a producer from a training.
  Future<void> removeAttendee(String trainingId, String producerId) async {
    await _conn.execute(
      Sql.named(
          'DELETE FROM training_attendees WHERE training_id = @tid AND producer_id = @pid'),
      parameters: {'tid': trainingId, 'pid': producerId},
    );
  }

  /// Mark attendance.
  Future<void> markAttendance(
      String trainingId, String producerId, bool attended) async {
    await _conn.execute(
      Sql.named('''
        UPDATE training_attendees SET attended = @attended
        WHERE training_id = @tid AND producer_id = @pid
      '''),
      parameters: {
        'tid': trainingId,
        'pid': producerId,
        'attended': attended,
      },
    );
  }

  Map<String, dynamic> _rowToMap(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'title': row['title'],
      'description': row['description'],
      'date': row['date']?.toString(),
      'location': row['location'],
      'attendeeCount': row['attendee_count'] ?? 0,
      'evaluationNotes': row['evaluation_notes'],
      'certificationIssued': row['certification_issued'] ?? false,
      'createdAt': row['created_at']?.toString(),
      'updatedAt': row['updated_at']?.toString(),
    };
  }
}
