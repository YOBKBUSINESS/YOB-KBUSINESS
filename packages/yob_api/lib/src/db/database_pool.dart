import 'dart:io';
import 'package:postgres/postgres.dart';

/// Connection pool wrapper for PostgreSQL.
///
/// Uses a pool of connections instead of a single connection
/// for better concurrent request handling.
class DatabasePool {
  static DatabasePool? _instance;
  Pool? _pool;

  DatabasePool._();

  static DatabasePool get instance {
    _instance ??= DatabasePool._();
    return _instance!;
  }

  Pool get pool {
    if (_pool == null) {
      throw StateError('Database pool not initialized. Call initialize() first.');
    }
    return _pool!;
  }

  Future<void> initialize() async {
    if (_pool != null) return;

    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final database = Platform.environment['DB_NAME'] ?? 'yob_kbusiness';
    final username = Platform.environment['DB_USER'] ?? 'yob_admin';
    final password = Platform.environment['DB_PASSWORD'] ?? 'yob_dev_password';

    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );

    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: int.parse(
          Platform.environment['DB_MAX_CONNECTIONS'] ?? '10',
        ),
        sslMode: SslMode.disable,
      ),
    );

    // Verify connectivity
    await _pool!.execute('SELECT 1');
    print('✅ Database pool initialized ($host:$port/$database)');
  }

  /// Execute a query using a pooled connection.
  Future<Result> execute(
    Object query, {
    Map<String, dynamic>? parameters,
  }) async {
    return pool.execute(
      query is Sql ? query : Sql.named(query.toString()),
      parameters: parameters,
    );
  }

  /// Run a transaction using a pooled connection.
  Future<T> runTx<T>(
    Future<T> Function(TxSession session) fn,
  ) async {
    return pool.runTx(fn);
  }

  Future<void> close() async {
    await _pool?.close();
    _pool = null;
    print('🔌 Database pool closed');
  }
}
