import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<({List<ProductItem> items, bool hasMore, int total})> fetchProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (category != null && category.trim().isNotEmpty && category != 'All' && category != 'all') {
      queryParams['category'] = category.trim();
    }
    if (rootCause != null && rootCause.trim().isNotEmpty && rootCause != 'All' && rootCause != 'all') {
      queryParams['root_cause'] = rootCause.trim();
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: queryParams,
      options: Options(extra: const {'silent': true}),
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      final rawList = data['items'] as List<dynamic>? ?? [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(ProductItem.fromJson)
          .toList();
      final hasMore = data['has_more'] == true;
      final total = (data['total'] as num?)?.toInt() ?? items.length;
      return (items: items, hasMore: hasMore, total: total);
    } else if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(ProductItem.fromJson)
          .toList();
      return (items: items, hasMore: false, total: items.length);
    }

    return (items: <ProductItem>[], hasMore: false, total: 0);
  }

  Future<ProductItem?> fetchProductById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.productById(cleanId),
      options: Options(extra: const {'silent': true}),
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return ProductItem.fromJson(data);
    }
    return null;
  }
}
