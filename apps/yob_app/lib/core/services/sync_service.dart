import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';
import '../utils/providers.dart';

/// Provider for the sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dioProvider));
});

/// Provider that tracks pending sync count.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return LocalCacheService.getPendingSyncCount();
});

/// Service that replays queued offline operations when connectivity returns.
class SyncService {
  final Dio _dio;
  bool _isSyncing = false;

  SyncService(this._dio);

  /// Attempt to sync all pending operations.
  /// Returns the number of successfully synced items.
  Future<int> syncPending() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    try {
      final pending = await LocalCacheService.getPendingSync();
      var synced = 0;

      for (final item in pending) {
        try {
          final method = item['method'] as String;
          final endpoint = item['endpoint'] as String;
          final bodyStr = item['body'] as String?;
          final body =
              bodyStr != null ? jsonDecode(bodyStr) as Map<String, dynamic>? : null;

          Response response;
          switch (method.toUpperCase()) {
            case 'POST':
              response = await _dio.post(endpoint, data: body);
            case 'PUT':
              response = await _dio.put(endpoint, data: body);
            case 'DELETE':
              response = await _dio.delete(endpoint);
            default:
              continue; // Skip unknown methods
          }

          if (response.statusCode != null && response.statusCode! < 400) {
            await LocalCacheService.markSynced(item['id'] as int);
            synced++;
          }
        } catch (_) {
          // If one fails, continue with others — it'll retry next time
          break; // Stop on first failure to preserve order
        }
      }

      // Clean up completed items
      if (synced > 0) {
        await LocalCacheService.clearSynced();
      }

      return synced;
    } finally {
      _isSyncing = false;
    }
  }
}

/// Widget-level mixin for auto-syncing when connectivity changes.
/// Usage: Add a listener in your root widget that watches connectivityProvider
/// and calls syncService.syncPending() when transitioning from offline → online.
class ConnectivitySyncObserver {
  final SyncService syncService;
  ConnectivityStatus? _previousStatus;

  ConnectivitySyncObserver(this.syncService);

  /// Call this when connectivity status changes. 
  /// Returns number of synced items if sync was triggered.
  Future<int?> onConnectivityChanged(ConnectivityStatus status) async {
    final wasOffline = _previousStatus == ConnectivityStatus.offline;
    _previousStatus = status;

    if (wasOffline && status == ConnectivityStatus.online) {
      return syncService.syncPending();
    }
    return null;
  }
}
