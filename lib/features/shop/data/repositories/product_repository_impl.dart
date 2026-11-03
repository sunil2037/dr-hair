import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<({List<ProductItem> items, bool hasMore, int total})> getProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchProducts(
        category: category,
        rootCause: rootCause,
        query: query,
        page: page,
        limit: limit,
      );
      return result;
    } catch (_) {
      // Never replace an API failure with fabricated catalog data.
      rethrow;
    }
  }

  @override
  Future<ProductItem?> getProductById(String id) async {
    try {
      final item = await _remoteDataSource.fetchProductById(id);
      if (item != null) return item;
    } catch (_) {
      rethrow;
    }

    return null;
  }
}
