import 'package:dr_hair/core/routes/app_destination.dart';
import 'package:dr_hair/features/shop/data/models/notification_item_model.dart';
import 'package:dr_hair/features/shop/data/repositories/notifications_repository.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/notifications_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/notifications_state.dart';
import 'package:dr_hair/features/shop/presentation/views/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockNotificationsRepository implements NotificationsRepository {
  List<NotificationItemModel> items = [];
  int unreadCount = 0;
  bool markAsReadCalled = false;
  bool markAllAsReadCalled = false;

  @override
  Future<({List<NotificationItemModel> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1, int limit = 20}) async {
    return (items: items, unreadCount: unreadCount, hasMore: false);
  }

  @override
  Future<bool> markAsRead(String id) async {
    markAsReadCalled = true;
    items = items.map((i) => i.id == id ? i.copyWith(isRead: true) : i).toList();
    unreadCount = items.where((i) => !i.isRead).length;
    return true;
  }

  @override
  Future<bool> markAllAsRead() async {
    markAllAsReadCalled = true;
    items = items.map((i) => i.copyWith(isRead: true)).toList();
    unreadCount = 0;
    return true;
  }
}

void main() {
  group('AppDestination & Push Notification Payload Routing', () {
    test('resolves product notification payload to exact product details path', () {
      final dest = AppDestination.fromNotificationData({
        'destination_type': 'product',
        'entity_id': 'prod-anti-dandruff-shampoo',
      });

      expect(dest.type, 'product');
      expect(dest.entityId, 'prod-anti-dandruff-shampoo');
      expect(dest.location, '/products/prod-anti-dandruff-shampoo');
    });

    test('resolves clinic appointment booking payload', () {
      final dest = AppDestination.fromNotificationData({
        'destination_type': 'screen',
        'screen': 'clinic_appointment',
      });

      expect(dest.type, 'screen');
      expect(dest.screen, 'clinic_appointment');
      expect(dest.location, '/clinic-appointment');
    });

    test('resolves orders history payload', () {
      final dest = AppDestination.fromNotificationData({
        'destination_type': 'screen',
        'screen': 'orders',
      });

      expect(dest.location, '/orders');
    });

    test('resolves hair test assessment payload', () {
      final dest = AppDestination.fromNotificationData({
        'destination_type': 'screen',
        'screen': 'hair_test',
      });

      expect(dest.location, '/hair-test');
    });
  });

  group('NotificationItemModel', () {
    test('parses json correctly with type and formatting', () {
      final model = NotificationItemModel.fromJson({
        'id': 'ntf-101',
        'title': 'Appointment Confirmed',
        'body': 'Your clinic sitting is confirmed for OPD Token #12.',
        'type': 'appointment',
        'destination': {
          'type': 'screen',
          'screen': 'clinic_appointment',
        },
        'isRead': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      expect(model.id, 'ntf-101');
      expect(model.title, 'Appointment Confirmed');
      expect(model.type, 'appointment');
      expect(model.isRead, false);
      expect(model.formattedTime, 'Just now');
      expect(model.destination.location, '/clinic-appointment');
    });
  });

  group('NotificationsCubit', () {
    late MockNotificationsRepository repo;

    setUp(() {
      repo = MockNotificationsRepository();
      repo.items = [
        NotificationItemModel(
          id: '1',
          title: 'Order Dispatched',
          body: 'Your kit is on the way.',
          type: 'order',
          destination: const AppDestination.screen('orders'),
          createdAt: DateTime.now(),
          isRead: false,
        ),
        NotificationItemModel(
          id: '2',
          title: 'Dr. Jai Consultation Note',
          body: 'Check your personalized routine.',
          type: 'treatment',
          destination: const AppDestination.screen('profile'),
          createdAt: DateTime.now(),
          isRead: true,
        ),
      ];
      repo.unreadCount = 1;
    });

    test('loadNotifications fetches items and unread count', () async {
      final cubit = NotificationsCubit(repository: repo);
      await cubit.loadNotifications();

      expect(cubit.state.notifications.length, 2);
      expect(cubit.state.unreadCount, 1);
      expect(cubit.state.isLoading, false);
      cubit.close();
    });

    test('markAsRead marks item read and decreases unreadCount', () async {
      final cubit = NotificationsCubit(repository: repo);
      await cubit.loadNotifications();

      await cubit.markAsRead('1');

      expect(cubit.state.notifications.first.isRead, true);
      expect(cubit.state.unreadCount, 0);
      expect(repo.markAsReadCalled, true);
      cubit.close();
    });

    test('markAllAsRead marks all read and sets unreadCount to 0', () async {
      final cubit = NotificationsCubit(repository: repo);
      await cubit.loadNotifications();

      await cubit.markAllAsRead();

      expect(cubit.state.notifications.every((n) => n.isRead), true);
      expect(cubit.state.unreadCount, 0);
      expect(repo.markAllAsReadCalled, true);
      cubit.close();
    });
  });

  group('NotificationsView Widget Tests', () {
    testWidgets('renders notifications and allows Read all action', (tester) async {
      final notif1 = NotificationItemModel(
        id: 'n1',
        title: 'Your order is on its way',
        body: 'We’ll let you know when it reaches your doorstep.',
        type: 'order',
        destination: const AppDestination.screen('orders'),
        createdAt: DateTime.now(),
        isRead: false,
      );
      final notif2 = NotificationItemModel(
        id: 'n2',
        title: 'Your care plan is ready',
        body: 'Your personalized routine is waiting in your profile.',
        type: 'treatment',
        destination: const AppDestination.screen('profile'),
        createdAt: DateTime.now(),
        isRead: true,
      );

      final mockRepo = MockNotificationsRepository();
      final cubit = NotificationsCubit(
        repository: mockRepo,
        initialState: NotificationsState(
          notifications: [notif1, notif2],
          unreadCount: 1,
          isLoading: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsView(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Your order is on its way'), findsOneWidget);
      expect(find.text('Your care plan is ready'), findsOneWidget);
      expect(find.text('Read all'), findsOneWidget);

      // Tap Read all
      await tester.tap(find.text('Read all'));
      await tester.pumpAndSettle();

      // Read all button disappears when unreadCount == 0
      expect(find.text('Read all'), findsNothing);
      expect(cubit.state.unreadCount, 0);

      cubit.close();
    });

    testWidgets('uses Skeletonizer shimmer during loading without CircularProgressIndicator',
        (tester) async {
      final mockRepo = MockNotificationsRepository();
      final cubit = NotificationsCubit(
        repository: mockRepo,
        initialState: const NotificationsState(
          isLoading: true,
          notifications: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsView(cubit: cubit),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsAtLeastNWidgets(1),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      cubit.close();
    });

    testWidgets('renders empty state when there are no notifications', (tester) async {
      final cubit = NotificationsCubit(
        initialState: const NotificationsState(
          isLoading: false,
          notifications: [],
          unreadCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsView(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.text(
          'Appointment updates, order tracking, and doctor care tips will appear here.',
        ),
        findsOneWidget,
      );
      expect(find.text('Read all'), findsNothing);

      cubit.close();
    });
  });
}
