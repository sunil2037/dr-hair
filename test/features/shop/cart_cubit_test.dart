import 'package:dio/dio.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/shop/data/datasources/cart_remote_data_source.dart';
import 'package:dr_hair/features/shop/data/models/product_model.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCartRemoteDataSource extends CartRemoteDataSource {
  int fetchCartCalls = 0;
  int addItemCalls = 0;
  int updateQuantityCalls = 0;
  int removeItemCalls = 0;
  int clearCartCalls = 0;
  int applyRewardCalls = 0;

  Map<String, dynamic>? mockCartData;

  _FakeCartRemoteDataSource() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>?> fetchCart() async {
    fetchCartCalls++;
    return mockCartData ??
        {
          'items': [
            {
              'id': 'prd-test-1::1 Month Supply',
              'productId': 'prd-test-1',
              'title': 'Test Tonic',
              'plan': '1 Month Supply',
              'price': 999,
              'quantity': 1,
              'image': 'https://res.cloudinary.com/test/image.jpg',
            }
          ],
          'summary': {
            'subtotal': 999,
            'discount': 0,
            'total': 999,
          }
        };
  }

  @override
  Future<Map<String, dynamic>?> addItem({
    required String productId,
    String? planTitle,
    int quantity = 1,
  }) async {
    addItemCalls++;
    return {'id': '$productId::$planTitle', 'quantity': quantity};
  }

  @override
  Future<Map<String, dynamic>?> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    updateQuantityCalls++;
    return {'id': itemId, 'quantity': quantity};
  }

  @override
  Future<Map<String, dynamic>?> removeItem(String itemId) async {
    removeItemCalls++;
    return {'removed': true};
  }

  @override
  Future<bool> clearCart() async {
    clearCartCalls++;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> applyReward(String code) async {
    applyRewardCalls++;
    return {'discount': 200, 'coupon': code};
  }
}

void main() {
  group('CartCubit Unit Tests', () {
    late AppLocalCache cache;

    setUp(() {
      cache = AppLocalCache.inMemory();
    });

    const testProduct = ProductItem(
      id: 'prd-99',
      name: 'Anti-Hairfall Shampoo',
      subtitle: 'Nourishing formula',
      category: 'Hair',
      rating: 4.8,
      reviewsCount: 120,
      inStock: true,
      images: ['https://res.cloudinary.com/test/shampoo.jpg'],
      supplyPlans: [
        ProductSupplyPlan(
          title: '3 Months Plan',
          subtitle: 'Best value',
          price: 1499,
          mrp: 1999,
          badge: 'Recommended',
        ),
      ],
      benefits: [],
      ingredients: [],
      usageSteps: [],
      clinicalMetrics: [],
    );

    test('initializes empty when no cache exists and syncWithBackend is false', () {
      final cubit = CartCubit(cache: cache, syncWithBackend: false);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.itemCount, 0);
      expect(cubit.state.subtotal, 0);
    });

    test('syncs items from remote data source on init', () async {
      final remote = _FakeCartRemoteDataSource();
      final cubit = CartCubit(
        cache: cache,
        remoteDataSource: remote,
        syncWithBackend: true,
      );

      // Allow async backend sync to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.fetchCartCalls, 1);
      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first['title'], 'Test Tonic');
      expect(cubit.state.itemCount, 1);
      expect(cubit.state.subtotal, 999);
    });

    test('addProduct adds item and notifies remoteDataSource', () async {
      final remote = _FakeCartRemoteDataSource();
      final cubit = CartCubit(
        cache: cache,
        remoteDataSource: remote,
        syncWithBackend: false,
      );

      cubit.addProduct(
        product: testProduct,
        plan: testProduct.supplyPlans.first,
        quantity: 2,
      );

      expect(cubit.state.items.length, 1);
      expect(cubit.state.itemCount, 2);
      expect(cubit.state.subtotal, 2998);
      expect(remote.addItemCalls, 1);
    });

    test('setQuantity updates quantity and clamp at max 10', () {
      final remote = _FakeCartRemoteDataSource();
      final cubit = CartCubit(
        cache: cache,
        remoteDataSource: remote,
        syncWithBackend: false,
      );

      cubit.addProduct(
        product: testProduct,
        plan: testProduct.supplyPlans.first,
        quantity: 1,
      );

      final lineId = CartCubit.lineId(testProduct.id, testProduct.supplyPlans.first.title);
      cubit.setQuantity(lineId, 15); // Exceeds 10

      expect(cubit.quantityFor(testProduct.id, testProduct.supplyPlans.first.title), 10);
      expect(remote.updateQuantityCalls, 1);
    });

    test('setting quantity to 0 removes the item and calls remote removeItem', () {
      final remote = _FakeCartRemoteDataSource();
      final cubit = CartCubit(
        cache: cache,
        remoteDataSource: remote,
        syncWithBackend: false,
      );

      cubit.addProduct(
        product: testProduct,
        plan: testProduct.supplyPlans.first,
        quantity: 1,
      );

      final lineId = CartCubit.lineId(testProduct.id, testProduct.supplyPlans.first.title);
      cubit.setQuantity(lineId, 0);

      expect(cubit.state.items, isEmpty);
      expect(remote.removeItemCalls, 1);
    });

    test('clear resets items and calls remote clearCart', () {
      final remote = _FakeCartRemoteDataSource();
      final cubit = CartCubit(
        cache: cache,
        remoteDataSource: remote,
        syncWithBackend: false,
      );

      cubit.addProduct(
        product: testProduct,
        plan: testProduct.supplyPlans.first,
        quantity: 1,
      );
      expect(cubit.state.items.isNotEmpty, isTrue);

      cubit.clear();
      expect(cubit.state.items, isEmpty);
      expect(remote.clearCartCalls, 1);
    });
  });
}
