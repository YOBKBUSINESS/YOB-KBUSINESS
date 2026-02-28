import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Notification bell icon with badge for the app bar.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => _showNotificationPanel(context, ref),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (_, scrollCtrl) =>
            _NotificationPanel(scrollController: scrollCtrl),
      ),
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  final ScrollController scrollController;

  const _NotificationPanel({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (notifications.isNotEmpty) ...[
                TextButton(
                  onPressed: () => notifier.markAllRead(),
                  child: const Text('Tout lire'),
                ),
                TextButton(
                  onPressed: () => notifier.clearAll(),
                  child: const Text('Effacer'),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune notification',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final n = notifications[i];
                    return Dismissible(
                      key: Key(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade50,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.red),
                      ),
                      onDismissed: (_) => notifier.remove(n.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _typeColor(n.type).withValues(alpha: 0.1),
                          child: Icon(_typeIcon(n.type),
                              color: _typeColor(n.type), size: 20),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.normal : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          n.body,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          dateFmt.format(n.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                        tileColor: n.isRead
                            ? null
                            : AppColors.primary.withValues(alpha: 0.03),
                        onTap: () {
                          notifier.markRead(n.id);
                          if (n.route != null) {
                            Navigator.pop(ctx);
                            context.go(n.route!);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.financial:
        return AppColors.secondary;
      case NotificationType.info:
        return AppColors.info;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.financial:
        return Icons.account_balance_wallet;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}
