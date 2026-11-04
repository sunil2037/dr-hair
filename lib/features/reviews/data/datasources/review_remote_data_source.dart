import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final Dio _dio;

  ReviewRemoteDataSource({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<List<ReviewModel>> getReviews({String? category, int? page}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/reviews/review_get',
        queryParameters: {
          if (category != null && category != 'All') 'category': category,
          'page': ?page,
        },
        options: Options(extra: const {'silent': true}),
      );

      final data = response.data?['data'];
      final rawList = data is List
          ? data
          : data is Map && data['items'] is List
              ? data['items'] as List
              : null;

      if (rawList != null && rawList.isNotEmpty) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
      }
    } catch (_) {
      // Fall back cleanly if backend is unreachable
    }

    return ReviewModel.defaultReviews;
  }
}
