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
}
