import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/services/auth_service.dart';
import 'package:yob_api/src/services/jwt_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

/// GET /api/v1/auth/me — Returns authenticated user info.
Future<Response> _onGet(RequestContext context) async {
  try {
    final jwtService = context.read<JwtService>();
    final authService = context.read<AuthService>();

    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Token manquant'},
      );
    }

    final token = authHeader.substring(7);
    final payload = jwtService.verifyToken(token);

    if (payload == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Token invalide ou expiré'},
      );
    }

    final userId = payload['user_id'] as String;
    final user = await authService.getUserById(userId);

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Utilisateur non trouvé'},
      );
    }

    return Response.json(
      body: {'success': true, 'data': user},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
