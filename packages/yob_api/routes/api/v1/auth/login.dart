import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

Future<Response> _onPost(RequestContext context) async {
  try {
    final authService = context.read<AuthService>();
    final body = await context.request.json() as Map<String, dynamic>;

    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Email et mot de passe requis'},
      );
    }

    final result = await authService.login(email, password);

    if (result == null) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'message': 'Identifiants invalides'},
      );
    }

    return Response.json(
      body: {'success': true, 'data': result},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
