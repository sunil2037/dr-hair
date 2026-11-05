import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/notification_item_model.dart';
import '../../data/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit({
    NotificationsRepository? repository,
    NotificationsState? initialState,
  })  : _repository = repository ?? NotificationsRepositoryImpl(),
        super(initialState ?? NotificationsState.initial());

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _repository.getNotifications(page: 1, limit: 20);
      emit(state.copyWith(
        notifications: result.items,
        unreadCount: result.unreadCount,
        hasMore: result.hasMore,
        currentPage: 1,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      ));
    }
  }

  Future<void> markAsRead(String id) async {
    final updatedList = state.notifications.map((NotificationItemModel item) {
      if (item.id == id && !item.isRead) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    final newUnreadCount = updatedList.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    ));

    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final updatedList = state.notifications.map((NotificationItemModel item) {
      return item.copyWith(isRead: true);
    }).toList();

    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    ));

    await _repository.markAllAsRead();
  }

  /// Immediately incorporates a real-time foreground push notification into the active
  /// state and bumps the unread badge count without waiting for full list reload.
  void onForegroundNotificationReceived({
    required String title,
    required String body,
    String? id,
    String? type,
    Map<String, dynamic>? data,
  }) {
    final notificationId =
        id ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}';

    // Guard against duplicates
    if (state.notifications.any((n) => n.id == notificationId)) {
      return;
    }

    final newItem = NotificationItemModel(
      id: notificationId,
      title: title,
      body: body,
      type: type ?? (data?['type']?.toString() ?? 'general'),
      destination: NotificationItemModel.fromJson({
        'type': data?['type'] ?? type ?? 'general',
        'screen': data?['screen'],
        'entity_id': data?['entity_id'] ?? data?['entityId'],
      }).destination,
      data: data ?? const {},
      isRead: false,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      notifications: [newItem, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    ));
  }

  /// Resets notifications state on patient logout.
  void reset() {
    emit(NotificationsState.initial());
  }
}
