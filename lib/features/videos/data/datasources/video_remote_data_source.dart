import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/video_story_model.dart';

class VideoRemoteDataSource {
  final Dio _dio;

  VideoRemoteDataSource({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<({List<VideoStoryModel> items, bool hasMore, int total, int page})>
      fetchVideos({
    int page = 1,
    int limit = 10,
    String? category,
    String? placement = 'reels',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (placement != null && placement.isNotEmpty) {
      queryParams['placement'] = placement;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.videos,
      queryParameters: queryParams,
      options: Options(extra: const {'silent': true}),
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      final rawList = data['items'] as List<dynamic>? ?? [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(VideoStoryModel.fromJson)
          .toList();
      final hasMore = data['has_more'] == true;
      final total = (data['total'] as num?)?.toInt() ?? items.length;
      final currentPage = (data['page'] as num?)?.toInt() ?? page;

      return (
        items: items,
        hasMore: hasMore,
        total: total,
        page: currentPage,
      );
    } else if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(VideoStoryModel.fromJson)
          .toList();
      return (
        items: items,
        hasMore: false,
        total: items.length,
        page: 1,
      );
    }

    return (items: <VideoStoryModel>[], hasMore: false, total: 0, page: page);
  }
}
