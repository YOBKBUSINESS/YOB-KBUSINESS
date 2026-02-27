import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/middleware/auth_middleware.dart';
import 'package:yob_api/src/services/jwt_service.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final jwtService = context.read<JwtService>();
    return authMiddleware(jwtService)(handler)(context);
  };
}
