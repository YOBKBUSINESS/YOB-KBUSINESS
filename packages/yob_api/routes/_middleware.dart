import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/db/database.dart';
import 'package:yob_api/src/services/auth_service.dart';
import 'package:yob_api/src/services/jwt_service.dart';

/// Root middleware — provides shared services to all routes.
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(_corsMiddleware())
      .use(_servicesProvider());
}

/// CORS middleware for web access.
Middleware _corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 204,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

/// Provide database and services to context.
Middleware _servicesProvider() {
  final db = Database.instance;
  final jwtService = JwtService();
  final authService = AuthService(db: db, jwtService: jwtService);

  // Initialize DB on first request
  var dbInitialized = false;

  return (handler) {
    return (context) async {
      if (!dbInitialized) {
        await db.initialize();
        dbInitialized = true;
      }

      final updatedContext = context
          .provide<Database>(() => db)
          .provide<JwtService>(() => jwtService)
          .provide<AuthService>(() => authService);

      return handler(updatedContext);
    };
  };
}
