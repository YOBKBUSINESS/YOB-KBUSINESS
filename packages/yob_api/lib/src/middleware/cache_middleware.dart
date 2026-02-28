import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../services/response_cache.dart';

/// Middleware that caches GET responses for a configurable TTL.
///
/// Usage in a `_middleware.dart`:
/// ```dart
/// Handler middleware(Handler handler) {
///   return handler.use(cacheMiddleware(ttl: Duration(minutes: 2)));
/// }
/// ```
Middleware cacheMiddleware({
  Duration ttl = ResponseCache.defaultTtl,
}) {
  final cache = ResponseCache.instance;

  return (handler) {
    return (context) async {
      final request = context.request;

      // Only cache GET requests
      if (request.method != HttpMethod.get) {
        // Invalidate cache on write operations
        if (request.method == HttpMethod.post ||
            request.method == HttpMethod.put ||
            request.method == HttpMethod.delete ||
            request.method == HttpMethod.patch) {
          final pathSegments = request.uri.pathSegments;
          if (pathSegments.length >= 3) {
            // Invalidate the resource collection path
            // e.g., /api/v1/producers/abc -> invalidate /api/v1/producers
            final resourcePath =
                '/${pathSegments.take(pathSegments.length > 3 ? 3 : pathSegments.length).join('/')}';
            cache.invalidate(resourcePath);
          }
        }
        return handler(context);
      }

      final cacheKey = cache.key(
        request.uri.path,
        request.uri.queryParameters,
      );

      // Check cache
      final cached = cache.get(cacheKey);
      if (cached != null) {
        return Response.json(
          body: jsonDecode(cached),
          headers: {'X-Cache': 'HIT'},
        );
      }

      // Execute handler
      final response = await handler(context);

      // Only cache successful responses
      if (response.statusCode == 200) {
        final body = await response.body();
        cache.put(cacheKey, body, ttl: ttl);
        return Response(
          statusCode: 200,
          body: body,
          headers: {
            ...response.headers,
            'X-Cache': 'MISS',
            'Content-Type': 'application/json',
          },
        );
      }

      return response;
    };
  };
}
