import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/services/auth_service.dart';
import 'package:yob_api/src/services/jwt_service.dart';

/// Require authentication for all investor routes.
Handler middleware(Handler handler) {
  return (context) async {
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Token requis'},
      );
    }

    final token = authHeader.substring(7);
    final jwtService = context.read<JwtService>();
    final payload = jwtService.verify(token);

    if (payload == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Token invalide'},
      );
    }

    final authService = context.read<AuthService>();
    final user = await authService.getUserById(payload['sub'] as String);
    if (user == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Utilisateur introuvable'},
      );
    }

    final updatedContext = context.provide<Map<String, dynamic>>(() => user);
    return handler(updatedContext);
  };
}
