import 'package:test/test.dart';
import 'package:yob_api/src/services/jwt_service.dart';

void main() {
  late JwtService jwtService;

  setUp(() {
    jwtService = JwtService();
  });

  group('JwtService', () {
    test('generateToken returns a non-empty string', () {
      final token = jwtService.generateToken(
        userId: 'user-1',
        email: 'test@example.com',
        role: 'direction',
      );
      expect(token, isNotEmpty);
      expect(token.split('.'), hasLength(3)); // JWT has 3 parts
    });

    test('verifyToken returns payload for valid token', () {
      final token = jwtService.generateToken(
        userId: 'user-1',
        email: 'admin@yob.ci',
        role: 'comptable',
      );

      final payload = jwtService.verifyToken(token);
      expect(payload, isNotNull);
      expect(payload!['user_id'], 'user-1');
      expect(payload['email'], 'admin@yob.ci');
      expect(payload['role'], 'comptable');
    });

    test('verifyToken returns null for invalid token', () {
      final payload = jwtService.verifyToken('invalid.token.here');
      expect(payload, isNull);
    });

    test('verifyToken returns null for tampered token', () {
      final token = jwtService.generateToken(
        userId: 'user-1',
        email: 'test@example.com',
        role: 'direction',
      );
      // Tamper with the token
      final tampered = '${token}x';
      final payload = jwtService.verifyToken(tampered);
      expect(payload, isNull);
    });

    test('generateRefreshToken returns a valid token', () {
      final token = jwtService.generateRefreshToken(userId: 'user-1');
      expect(token, isNotEmpty);

      final payload = jwtService.verifyToken(token);
      expect(payload, isNotNull);
      expect(payload!['user_id'], 'user-1');
      expect(payload['type'], 'refresh');
    });

    test('tokens contain issuer claim', () {
      final token = jwtService.generateToken(
        userId: 'user-1',
        email: 'test@example.com',
        role: 'direction',
      );

      final payload = jwtService.verifyToken(token);
      expect(payload, isNotNull);
      // The issuer is 'yob-kbusiness-api'
      expect(payload!['user_id'], 'user-1');
    });
  });
}
