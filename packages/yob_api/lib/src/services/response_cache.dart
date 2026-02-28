import 'dart:async';
import 'dart:convert';

/// In-memory server-side response cache with TTL support.
///
/// Caches GET responses to reduce database load for frequently
/// requested data (dashboard stats, lists with same parameters).
class ResponseCache {
  static final ResponseCache instance = ResponseCache._();

  ResponseCache._();

  final _cache = <String, _CacheEntry>{};
  Timer? _cleanupTimer;

  /// Default TTL: 30 seconds for most endpoints.
  static const defaultTtl = Duration(seconds: 30);

  /// Longer TTL for dashboard stats: 2 minutes.
  static const dashboardTtl = Duration(minutes: 2);

  /// Short TTL for auth-related data: 10 seconds.
  static const shortTtl = Duration(seconds: 10);

  /// Start periodic cleanup of expired entries.
  void startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _evictExpired();
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  /// Generates a cache key from the request path and query parameters.
  String key(String path, [Map<String, String>? queryParams]) {
    if (queryParams == null || queryParams.isEmpty) return path;
    final sorted = queryParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryString = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?$queryString';
  }

  /// Get a cached response. Returns null if not found or expired.
  String? get(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(cacheKey);
      return null;
    }
    return entry.data;
  }

  /// Store a response in the cache.
  void put(String cacheKey, Object data, {Duration ttl = defaultTtl}) {
    final jsonData = data is String ? data : jsonEncode(data);
    _cache[cacheKey] = _CacheEntry(
      data: jsonData,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Invalidate entries matching a path prefix.
  ///
  /// Call this after POST/PUT/DELETE operations to clear stale data.
  /// e.g., `invalidate('/api/v1/producers')` clears all producer caches.
  void invalidate(String pathPrefix) {
    _cache.removeWhere((key, _) => key.startsWith(pathPrefix));
  }

  /// Invalidate all cached data.
  void invalidateAll() {
    _cache.clear();
  }

  /// Current size of the cache.
  int get size => _cache.length;

  void _evictExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

class _CacheEntry {
  final String data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
