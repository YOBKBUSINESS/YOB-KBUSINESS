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
    final fullName = body['full_name'] as String?;
    final phone = body['phone'] as String?;
    final role = body['role'] as String? ?? 'superviseur';

    if (email == null || password == null || fullName == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Email, mot de passe et nom complet requis',
        },
      );
    }

    if (password.length < 6) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Le mot de passe doit contenir au moins 6 caractères',
        },
      );
    }

    final result = await authService.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
    );

    if (result == null) {
      return Response.json(
        statusCode: 409,
        body: {
          'success': false,
          'message': 'Un utilisateur avec cet email existe déjà',
        },
      );
    }

    return Response.json(
      statusCode: 201,
      body: {'success': true, 'data': result},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
