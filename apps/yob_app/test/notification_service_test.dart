import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_app/core/services/notification_service.dart';
import 'package:yob_app/core/widgets/notification_bell.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('starts with empty notifications', () {
      expect(service.state, isEmpty);
      expect(service.unreadCount, 0);
    });

    test('push adds notification', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Test body',
        createdAt: DateTime.now(),
      ));
      expect(service.state, hasLength(1));
      expect(service.unreadCount, 1);
    });

    test('markRead updates notification', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Test body',
        createdAt: DateTime.now(),
      ));
      service.markRead('n1');
      expect(service.unreadCount, 0);
      expect(service.state.first.isRead, true);
    });

    test('markAllRead marks all as read', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'Test1',
        body: 'Body1',
        createdAt: DateTime.now(),
      ));
      service.push(AppNotification(
        id: 'n2',
        title: 'Test2',
        body: 'Body2',
        createdAt: DateTime.now(),
      ));
      expect(service.unreadCount, 2);
      service.markAllRead();
      expect(service.unreadCount, 0);
    });

    test('remove removes notification', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now(),
      ));
      service.remove('n1');
      expect(service.state, isEmpty);
    });

    test('clearAll clears all notifications', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        createdAt: DateTime.now(),
      ));
      service.push(AppNotification(
        id: 'n2',
        title: 'Test2',
        body: 'Body2',
        createdAt: DateTime.now(),
      ));
      service.clearAll();
      expect(service.state, isEmpty);
    });

    test('pushTreasuryAlert creates financial notification', () {
      service.pushTreasuryAlert(balance: 300000, threshold: 500000);
      expect(service.state, hasLength(1));
      expect(service.state.first.type, NotificationType.financial);
      expect(service.state.first.title, 'Alerte Trésorerie');
      expect(service.state.first.route, '/finances/dashboard');
    });

    test('pushSyncComplete creates info notification', () {
      service.pushSyncComplete(count: 5);
      expect(service.state, hasLength(1));
      expect(service.state.first.type, NotificationType.info);
      expect(service.state.first.body, contains('5'));
    });

    test('pushNewInvestor creates info notification', () {
      service.pushNewInvestor(name: 'Jean', amount: 1000000);
      expect(service.state, hasLength(1));
      expect(service.state.first.body, contains('Jean'));
      expect(service.state.first.route, '/investors');
    });

    test('new notifications appear at the top', () {
      service.push(AppNotification(
        id: 'n1',
        title: 'First',
        body: 'Body',
        createdAt: DateTime.now(),
      ));
      service.push(AppNotification(
        id: 'n2',
        title: 'Second',
        body: 'Body',
        createdAt: DateTime.now(),
      ));
      expect(service.state.first.title, 'Second');
    });
  });

  group('NotificationBell widget', () {
    testWidgets('shows badge when notifications exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationProvider.overrideWith(
              (ref) {
                final svc = NotificationService();
                svc.push(AppNotification(
                  id: 'n1',
                  title: 'Test',
                  body: 'Body',
                  createdAt: DateTime.now(),
                ));
                return svc;
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: null,
              body: NotificationBell(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Should show badge with "1"
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('hides badge when no notifications',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NotificationBell()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      // No badge text should be visible
      expect(find.text('0'), findsNothing);
    });
  });
}
