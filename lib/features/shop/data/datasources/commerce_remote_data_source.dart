import 'package:dio/dio.dart';
import 'package:dr_hair/features/care/domain/models/care_models.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_session_store.dart';
import '../models/delivery_address_model.dart';

class CommerceRemoteDataSource {
  final Dio _dio;
  final SecureSessionStore _sessionStore;

  CommerceRemoteDataSource({Dio? dio, SecureSessionStore? sessionStore})
    : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio,
      _sessionStore = sessionStore ?? SecureSessionStore();

  Future<Map<String, String>> _buildHeaders({String? token}) async {
    final activeToken = token ?? await _sessionStore.readToken();
    if (activeToken != null && activeToken.trim().isNotEmpty) {
      return {'Authorization': 'Bearer ${activeToken.trim()}'};
    }
    return {};
  }

  Future<List<DeliveryAddress>> fetchAddresses({String? token}) async {
    try {
      final headers = await _buildHeaders(token: token);
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientAddresses,
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => DeliveryAddress.fromJson(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<DeliveryAddress?> createAddress({
    String? token,
    required DeliveryAddress address,
  }) async {
    try {
      final headers = await _buildHeaders(token: token);
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientAddresses,
        data: address.toJson(),
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return DeliveryAddress.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> checkout({
    String? token,
    required String idempotencyKey,
    String? addressId,
    DeliveryAddress? shippingAddress,
    required List<Map<String, dynamic>> items,
    String? couponCode,
  }) async {
    final headers = await _buildHeaders(token: token);
    headers['Idempotency-Key'] = idempotencyKey;

    final body = <String, dynamic>{'items': items};
    if (addressId != null && addressId.isNotEmpty) {
      body['address_id'] = addressId;
    }
    if (shippingAddress != null) {
      body['shipping_address'] = shippingAddress.toJson();
    }
    if (couponCode != null && couponCode.isNotEmpty) {
      body['coupon_code'] = couponCode;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.commerceCheckout,
      data: body,
      options: Options(headers: headers),
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Invalid checkout response format');
  }

  Future<Map<String, dynamic>> verifyPayment({
    String? token,
    required String orderId,
    required String paymentId,
    String? paymentSignature,
  }) async {
    final headers = await _buildHeaders(token: token);
    final payload = <String, dynamic>{
      'order_id': orderId,
      'payment_id': paymentId,
    };
    if (paymentSignature != null && paymentSignature.isNotEmpty) {
      payload['payment_signature'] = paymentSignature;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.commerceVerifyPayment,
      data: payload,
      options: Options(headers: headers),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Invalid payment verification response');
  }

  Future<List<CareOrder>> fetchPatientOrders({
    String? token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _buildHeaders(token: token);
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientOrders,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      final items = data is Map ? data['items'] : data;
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map((item) => CareOrder.fromJson(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<CareOrder?> cancelOrder({
    String? token,
    required String orderId,
    String? reason,
  }) async {
    final headers = await _buildHeaders(token: token);
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.patientOrderCancel(orderId),
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      options: Options(headers: headers),
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return CareOrder.fromJson(data);
    }
    return null;
  }
}
