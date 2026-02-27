import 'dart:io';
import 'package:postgres/postgres.dart';

class Database {
  static Database? _instance;
  late Connection _connection;

  Database._();

  static Database get instance {
    _instance ??= Database._();
    return _instance!;
  }

  Connection get connection => _connection;

  Future<void> initialize() async {
    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final database = Platform.environment['DB_NAME'] ?? 'yob_kbusiness';
    final username = Platform.environment['DB_USER'] ?? 'yob_admin';
    final password = Platform.environment['DB_PASSWORD'] ?? 'yob_dev_password';

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    print('✅ Connected to PostgreSQL at $host:$port/$database');
  }

  Future<void> close() async {
    await _connection.close();
    print('🔌 Database connection closed');
  }
}
