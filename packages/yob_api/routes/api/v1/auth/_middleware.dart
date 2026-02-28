import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/middleware/rate_limiter.dart';

/// Auth-specific middleware — applies stricter rate limiting
/// on login / register / refresh endpoints to prevent brute-force attacks.
Handler middleware(Handler handler) {
  return handler.use(authRateLimitMiddleware());
}
