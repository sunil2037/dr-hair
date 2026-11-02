import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_item_model.dart';

abstract class NotificationsRepository {
  Future<({List<NotificationItemModel> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1, int limit = 20});
  Future<bool> markAsRead(String id);
  Future<bool> markAllAsRead();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final Dio _dio;

  NotificationsRepositoryImpl({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  @override
  Future<({List<NotificationItemModel> items, int unreadCount, bool hasMore})>
      getNotifications({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final rawList = data['items'] as List<dynamic>? ?? [];
    final unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
    final hasMore = data['hasMore'] as bool? ?? false;

    final items = rawList
        .map((item) => NotificationItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return (items: items, unreadCount: unreadCount, hasMore: hasMore);
  }

  @override
  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dio.patch('/api/v1/notifications/$id/read');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.post('/api/v1/notifications/read-all');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
