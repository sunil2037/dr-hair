import 'package:dr_hair/features/shop/data/models/product_model.dart';

abstract class ProductRepository {
  Future<({List<ProductItem> items, bool hasMore, int total})> getProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  });

  Future<ProductItem?> getProductById(String id);
}
