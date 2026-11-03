import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class ContentItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String content;
  final String imageUrl;
  final String actionUrl;
  final String placement;
  final String status;
  final String? approvedBy;

  const ContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.content = '',
    this.imageUrl = '',
    this.actionUrl = '',
    this.placement = 'home',
    this.status = 'published',
    this.approvedBy,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final prov = json['provenance'] is Map ? json['provenance'] as Map : const {};
    return ContentItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'tip',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      actionUrl: json['actionUrl']?.toString() ?? '',
      placement: json['placement']?.toString() ?? 'home',
      status: json['status']?.toString() ?? 'published',
      approvedBy: prov['approved_by']?.toString(),
    );
  }
}

class ContentApi {
  final Dio _dio;

  ContentApi({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<List<ContentItem>> getPublishedContent({String? type, String? placement}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (placement != null) queryParams['placement'] = placement;

      final response = await _dio.get(
        '/api/v1/content',
        queryParameters: queryParams,
      );

      final data = response.data;
      final rawItems = data is Map && data['data'] is List
          ? data['data'] as List
          : data is List
              ? data
              : const [];

      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(ContentItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
