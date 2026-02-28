import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification model used throughout the app.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? route; // deep-link route on tap
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.type = NotificationType.info,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        route: route,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

enum NotificationType { info, warning, alert, financial }

/// In-app notification service.
/// Currently uses local state; swap in Firebase Cloud Messaging for production.
class NotificationService extends StateNotifier<List<AppNotification>> {
  NotificationService() : super([]);

  /// Add a notification (from local trigger or FCM).
  void push(AppNotification notification) {
    state = [notification, ...state];
  }

  /// Mark a notification as read.
  void markRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  /// Mark all as read.
  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  /// Remove a notification.
  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  /// Clear all notifications.
  void clearAll() {
    state = [];
  }

  /// Get unread count.
  int get unreadCount => state.where((n) => !n.isRead).length;

  // ── Convenience factory methods for common notifications ──

  void pushTreasuryAlert({required double balance, required double threshold}) {
    push(AppNotification(
      id: 'treasury_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Alerte Trésorerie',
      body: 'Solde bas: ${balance.toStringAsFixed(0)} FCFA (seuil: ${threshold.toStringAsFixed(0)} FCFA)',
      route: '/finances/dashboard',
      type: NotificationType.financial,
      createdAt: DateTime.now(),
    ));
  }

  void pushSyncComplete({required int count}) {
    push(AppNotification(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Synchronisation terminée',
      body: '$count opération(s) synchronisée(s)',
      type: NotificationType.info,
      createdAt: DateTime.now(),
    ));
  }

  void pushNewInvestor({required String name, required double amount}) {
    push(AppNotification(
      id: 'investor_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nouvel investisseur',
      body: '$name — ${amount.toStringAsFixed(0)} FCFA',
      route: '/investors',
      type: NotificationType.info,
      createdAt: DateTime.now(),
    ));
  }
}

/// Provider for the notification service.
final notificationProvider =
    StateNotifierProvider<NotificationService, List<AppNotification>>(
  (ref) => NotificationService(),
);

/// Unread count provider (for badges).
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});
