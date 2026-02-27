import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtService {
  late final String _secret;
  late final int _expirationSeconds;

  JwtService() {
    _secret =
        Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-in-production';
    _expirationSeconds =
        int.parse(Platform.environment['JWT_EXPIRATION'] ?? '86400'); // 24h
  }

  String generateToken({
    required String userId,
    required String email,
    required String role,
  }) {
    final jwt = JWT(
      {
        'user_id': userId,
        'email': email,
        'role': role,
      },
      issuer: 'yob-kbusiness-api',
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: Duration(seconds: _expirationSeconds),
    );
  }

  String generateRefreshToken({required String userId}) {
    final jwt = JWT(
      {'user_id': userId, 'type': 'refresh'},
      issuer: 'yob-kbusiness-api',
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: const Duration(days: 30),
    );
  }

  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      return null;
    } on JWTException {
      return null;
    }
  }
}
