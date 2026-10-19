import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'failure.dart';

class DioClient {
  late final Dio dio;

  DioClient({Dio? customDio}) {
    dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(milliseconds: ApiEndpoints.connectTimeout),
            receiveTimeout: const Duration(milliseconds: ApiEndpoints.receiveTimeout),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  static Failure handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkFailure(message: 'Connection timed out');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          final msg = (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Server responded with status $statusCode';
          return ServerFailure(message: msg, statusCode: statusCode);
        case DioExceptionType.cancel:
          return const Failure(message: 'Request was cancelled');
        case DioExceptionType.connectionError:
          return const NetworkFailure(message: 'No internet connection');
        default:
          return Failure(message: error.message ?? 'Unexpected error occurred');
      }
    }
    return Failure(message: error.toString());
  }
}
