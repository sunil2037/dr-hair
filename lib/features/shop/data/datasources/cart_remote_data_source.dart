import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../../../../core/storage/secure_session_store.dart';

class CartRemoteDataSource {
  final Dio _dio;
  final SecureSessionStore _sessionStore;
  final AppLocalCache _cache;

  CartRemoteDataSource({
    Dio? dio,
    SecureSessionStore? sessionStore,
    AppLocalCache? cache,
  })  : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio,
        _sessionStore = sessionStore ?? SecureSessionStore(),
        _cache = cache ?? AppLocalCache.instance;

  static const String _guestKey = 'shop_guest_session_id';

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _sessionStore.readToken();
    if (token != null && token.trim().isNotEmpty) {
      return {'Authorization': 'Bearer ${token.trim()}'};
    }
    var guestId = _cache.getString(_guestKey);
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await _cache.put(_guestKey, guestId);
    }
    return {'x-guest-session-id': guestId};
  }

  Future<Map<String, dynamic>?> fetchCart() async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.cart,
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      // Gracefully silent on network issues
    }
    return null;
  }

  Future<Map<String, dynamic>?> addItem({
    required String productId,
    String? planTitle,
    int quantity = 1,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartItems,
        data: {
          'productId': productId,
          if (planTitle != null && planTitle.isNotEmpty) 'planTitle': planTitle,
          'quantity': quantity,
        },
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.cartItemById(itemId),
        data: {'quantity': quantity},
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> removeItem(String itemId) async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.cartItemById(itemId),
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> clearCart() async {
    try {
      final headers = await _buildHeaders();
      await _dio.delete(
        ApiEndpoints.cart,
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? message, int discount, int total})>
  applyCoupon(String code) async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartCoupon,
        data: {'code': code.trim().toUpperCase()},
        options: Options(headers: headers, extra: const {'silent': true}),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        final discount = (data['discount'] as num?)?.toInt() ?? 0;
        final total = (data['total'] as num?)?.toInt() ?? 0;
        final message = response.data?['message']?.toString();
        return (
          success: true,
          message: message,
          discount: discount,
          total: total,
        );
      }
    } on DioException catch (dioErr) {
      final resMsg = dioErr.response?.data?['message']?.toString();
      return (
        success: false,
        message: resMsg ?? 'Invalid or expired coupon code.',
        discount: 0,
        total: 0,
      );
    } catch (_) {
      return (
        success: false,
        message: 'Could not apply coupon. Please check connection.',
        discount: 0,
        total: 0,
      );
    }
    return (
      success: false,
      message: 'Invalid coupon code.',
      discount: 0,
      total: 0,
    );
  }

  Future<Map<String, dynamic>?> applyReward(String code) async {
    try {
      final headers = await _buildHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartApplyReward,
        data: {'code': code.trim().toUpperCase()},
        options: Options(
          headers: headers,
          extra: const {'silent': true},
        ),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return null;
  }
}
