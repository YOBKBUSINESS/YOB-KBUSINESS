import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Banner displayed when the app is offline.
/// Place this at the top of your Scaffold body or in a Column.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return connectivity.when(
      data: (status) {
        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }
        final pending = pendingCount.valueOrNull ?? 0;
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Colors.orange.shade50,
          leading: const Icon(Icons.cloud_off, color: Colors.orange),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mode hors ligne',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                pending > 0
                    ? '$pending opération(s) en attente de synchronisation'
                    : 'Les données seront synchronisées à la reconnexion',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final syncService = ref.read(syncServiceProvider);
                final synced = await syncService.syncPending();
                if (context.mounted && synced > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$synced opération(s) synchronisée(s)'),
                    ),
                  );
                  ref.invalidate(pendingSyncCountProvider);
                }
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Compact offline indicator (for app bars, etc.).
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      data: (status) {
        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 14, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                'Hors ligne',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
