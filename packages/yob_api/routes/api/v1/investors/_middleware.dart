import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/middleware/auth_middleware.dart';
import 'package:yob_api/src/services/jwt_service.dart';

/// Middleware for /api/v1/investors — requires authentication.
Handler middleware(Handler handler) {
  return (context) async {
    final jwtService = context.read<JwtService>();
    return authMiddleware(jwtService)(handler)(context);
  };
}
