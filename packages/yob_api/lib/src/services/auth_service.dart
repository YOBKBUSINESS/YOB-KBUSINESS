import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import 'jwt_service.dart';

class AuthService {
  final Database _db;
  final JwtService _jwtService;
  final _uuid = const Uuid();

  AuthService({required Database db, required JwtService jwtService})
      : _db = db,
        _jwtService = jwtService;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final result = await _db.connection.execute(
      Sql.named('SELECT * FROM users WHERE email = @email AND is_active = true'),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    final storedHash = row['password_hash'] as String;

    if (!BCrypt.checkpw(password, storedHash)) return null;

    final userId = row['id'].toString();
    final role = row['role'] as String;

    final token = _jwtService.generateToken(
      userId: userId,
      email: email,
      role: role,
    );

    final refreshToken = _jwtService.generateRefreshToken(userId: userId);

    return {
      'token': token,
      'refresh_token': refreshToken,
      'user': {
        'id': userId,
        'email': row['email'],
        'full_name': row['full_name'],
        'phone': row['phone'],
        'role': role,
        'is_active': row['is_active'],
      },
    };
  }

  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'superviseur',
  }) async {
    // Check if user already exists
    final existing = await _db.connection.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    if (existing.isNotEmpty) return null;

    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());
    final id = _uuid.v4();

    await _db.connection.execute(
      Sql.named('''
        INSERT INTO users (id, email, password_hash, full_name, phone, role)
        VALUES (@id, @email, @password_hash, @full_name, @phone, @role::user_role)
      '''),
      parameters: {
        'id': id,
        'email': email,
        'password_hash': passwordHash,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      },
    );

    return login(email, password);
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final result = await _db.connection.execute(
      Sql.named(
        'SELECT id, email, full_name, phone, role, is_active, created_at, updated_at FROM users WHERE id = @id::uuid',
      ),
      parameters: {'id': userId},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return {
      'id': row['id'].toString(),
      'email': row['email'],
      'full_name': row['full_name'],
      'phone': row['phone'],
      'role': row['role'] as String,
      'is_active': row['is_active'],
      'created_at': row['created_at'].toString(),
      'updated_at': row['updated_at'].toString(),
    };
  }

  Future<Map<String, dynamic>?> refreshToken(String token) async {
    final payload = _jwtService.verifyToken(token);
    if (payload == null) return null;

    if (payload['type'] != 'refresh') return null;

    final userId = payload['user_id'] as String;
    final user = await getUserById(userId);
    if (user == null) return null;

    final newToken = _jwtService.generateToken(
      userId: userId,
      email: user['email'] as String,
      role: user['role'] as String,
    );

    final newRefresh = _jwtService.generateRefreshToken(userId: userId);

    return {
      'token': newToken,
      'refresh_token': newRefresh,
      'user': user,
    };
  }
}
