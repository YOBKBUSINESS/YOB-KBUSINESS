import 'package:dart_frog/dart_frog.dart';
import '../services/jwt_service.dart';

/// Middleware that verifies JWT token and attaches user info to the request.
Middleware authMiddleware(JwtService jwtService) {
  return (handler) {
    return (context) async {
      final request = context.request;
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Token manquant ou invalide'},
        );
      }

      final token = authHeader.substring(7);
      final payload = jwtService.verifyToken(token);

      if (payload == null) {
        return Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Token expiré ou invalide'},
        );
      }

      // Attach user info to context
      final updatedContext = context
          .provide<String>(() => payload['user_id'] as String)
          .provide<Map<String, dynamic>>(() => payload);

      return handler(updatedContext);
    };
  };
}

/// Middleware that checks if user has required role.
Middleware roleMiddleware(List<String> allowedRoles) {
  return (handler) {
    return (context) async {
      try {
        final userPayload = context.read<Map<String, dynamic>>();
        final userRole = userPayload['role'] as String;

        if (!allowedRoles.contains(userRole)) {
          return Response.json(
            statusCode: 403,
            body: {
              'success': false,
              'message': 'Accès refusé. Rôle insuffisant.',
            },
          );
        }

        return handler(context);
      } catch (_) {
        return Response.json(
          statusCode: 401,
          body: {'success': false, 'message': 'Non authentifié'},
        );
      }
    };
  };
}
