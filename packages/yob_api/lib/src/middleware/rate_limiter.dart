import 'dart:async';
import 'package:dart_frog/dart_frog.dart';

/// In-memory rate limiter using a sliding window per IP.
///
/// Defaults: 60 requests per minute for general endpoints,
/// 5 requests per minute for auth endpoints.
class RateLimiter {
  RateLimiter({
    required this.maxRequests,
    required this.window,
  });

  final int maxRequests;
  final Duration window;

  /// IP -> list of timestamps within the window.
  final _requests = <String, List<DateTime>>{};

  /// Periodic cleanup timer.
  Timer? _cleanupTimer;

  /// Starts a periodic cleanup of expired entries (every 5 min).
  void startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanup();
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  /// Returns true if the request is allowed.
  bool isAllowed(String clientIp) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);

    // Get or create the timestamp list for this IP.
    final timestamps = _requests.putIfAbsent(clientIp, () => []);

    // Remove old timestamps outside the window.
    timestamps.removeWhere((t) => t.isBefore(cutoff));

    if (timestamps.length >= maxRequests) {
      return false;
    }

    timestamps.add(now);
    return true;
  }

  /// Remaining requests for this IP within the current window.
  int remaining(String clientIp) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    final timestamps = _requests[clientIp] ?? [];
    final active = timestamps.where((t) => t.isAfter(cutoff)).length;
    return (maxRequests - active).clamp(0, maxRequests);
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(window);
    _requests.removeWhere((_, timestamps) {
      timestamps.removeWhere((t) => t.isBefore(cutoff));
      return timestamps.isEmpty;
    });
  }
}

// ── Singletons ──────────────────────────────────────────────────────────────

/// General API rate limiter: 100 requests per minute.
final apiRateLimiter = RateLimiter(
  maxRequests: 100,
  window: const Duration(minutes: 1),
)..startCleanup();

/// Auth rate limiter (login / register): 10 attempts per minute.
final authRateLimiter = RateLimiter(
  maxRequests: 10,
  window: const Duration(minutes: 1),
)..startCleanup();

// ── Middleware factories ────────────────────────────────────────────────────

/// Extracts client IP from the request (supports X-Forwarded-For).
String _clientIp(Request request) {
  return request.headers['x-forwarded-for']?.split(',').first.trim() ??
      request.headers['x-real-ip'] ??
      '0.0.0.0';
}

/// General rate-limiting middleware for all API routes.
Middleware rateLimitMiddleware() {
  return (handler) {
    return (context) async {
      final ip = _clientIp(context.request);

      if (!apiRateLimiter.isAllowed(ip)) {
        return Response.json(
          statusCode: 429,
          body: {
            'success': false,
            'message': 'Trop de requêtes. Réessayez plus tard.',
          },
          headers: {
            'Retry-After': '60',
            'X-RateLimit-Limit': '${apiRateLimiter.maxRequests}',
            'X-RateLimit-Remaining': '0',
          },
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          'X-RateLimit-Limit': '${apiRateLimiter.maxRequests}',
          'X-RateLimit-Remaining': '${apiRateLimiter.remaining(ip)}',
        },
      );
    };
  };
}

/// Stricter rate limiter for authentication endpoints.
Middleware authRateLimitMiddleware() {
  return (handler) {
    return (context) async {
      final ip = _clientIp(context.request);

      if (!authRateLimiter.isAllowed(ip)) {
        return Response.json(
          statusCode: 429,
          body: {
            'success': false,
            'message':
                'Trop de tentatives de connexion. Réessayez dans 1 minute.',
          },
          headers: {'Retry-After': '60'},
        );
      }

      return handler(context);
    };
  };
}
