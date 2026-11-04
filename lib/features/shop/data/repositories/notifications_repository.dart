import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_session_store.dart';
import '../models/notification_item_model.dart';

abstract class NotificationsRepository {
  Future<({List<NotificationItemModel> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1, int limit = 20});
  Future<bool> markAsRead(String id);
  Future<bool> markAllAsRead();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final Dio _dio;
  final SecureSessionStore _sessionStore;

  NotificationsRepositoryImpl({Dio? dio, SecureSessionStore? sessionStore})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio,
        _sessionStore = sessionStore ?? SecureSessionStore();

  @override
  Future<({List<NotificationItemModel> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1, int limit = 20}) async {
    // Guest or unauthenticated users have no remote notifications
    final token = await _sessionStore.readToken();
    if (token == null || token.trim().isEmpty) {
      return (
        items: <NotificationItemModel>[],
        unreadCount: 0,
        hasMore: false,
      );
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer ${token.trim()}'}),
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final rawList = data['items'] as List<dynamic>? ?? [];
      final unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
      final hasMore = data['hasMore'] as bool? ?? false;

      final items = rawList
          .map((item) =>
              NotificationItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return (items: items, unreadCount: unreadCount, hasMore: hasMore);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return (
          items: <NotificationItemModel>[],
          unreadCount: 0,
          hasMore: false,
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> markAsRead(String id) async {
    try {
      final token = await _sessionStore.readToken();
      final response = await _dio.patch(
        ApiEndpoints.notificationRead(id),
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer ${token.trim()}'})
            : null,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final token = await _sessionStore.readToken();
      final response = await _dio.post(
        ApiEndpoints.notificationsReadAll,
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer ${token.trim()}'})
            : null,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
