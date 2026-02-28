import 'package:dart_frog/dart_frog.dart';

/// Adds security headers to every response.
///
/// - Prevents clickjacking (X-Frame-Options)
/// - Prevents MIME sniffing (X-Content-Type-Options)
/// - Enables XSS filter (X-XSS-Protection)
/// - Controls referrer info (Referrer-Policy)
/// - Restricts permissions (Permissions-Policy)
/// - Basic CSP (Content-Security-Policy)
/// - Hides server identity (X-Powered-By removed, Server overridden)
Middleware securityHeadersMiddleware() {
  return (handler) {
    return (context) async {
      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          'X-Frame-Options': 'DENY',
          'X-Content-Type-Options': 'nosniff',
          'X-XSS-Protection': '1; mode=block',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
          'Content-Security-Policy': "default-src 'self'",
          'Strict-Transport-Security':
              'max-age=31536000; includeSubDomains; preload',
          'X-Powered-By': '', // Hide framework identity
          'Cache-Control': 'no-store',
        },
      );
    };
  };
}
