import '../../data/models/notification_item_model.dart';

class NotificationsState {
  final List<NotificationItemModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.errorMessage,
  });

  factory NotificationsState.initial() => const NotificationsState(
        isLoading: true,
      );

  NotificationsState copyWith({
    List<NotificationItemModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }
}
