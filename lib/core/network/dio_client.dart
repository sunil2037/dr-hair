import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/api_endpoints.dart';
import 'failure.dart';

/// DioClient with:
/// 1. Global network loading state (`DioClient.isLoading`)
/// 2. Yellow ANSI color console logger for Request, Response, and Errors
class DioClient {
  late final Dio dio;

  /// Global loading notifier for all active network requests
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  static int _activeRequests = 0;

  static void _startLoading() {
    _activeRequests++;
    if (!isLoading.value) {
      isLoading.value = true;
    }
  }

  static void _stopLoading() {
    _activeRequests = (_activeRequests - 1).clamp(0, 9999);
    if (_activeRequests == 0 && isLoading.value) {
      isLoading.value = false;
    }
  }

  DioClient({Dio? customDio, String? baseUrl, bool enableDebugLogging = true}) {
    dio =
        customDio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
            connectTimeout: const Duration(
              milliseconds: ApiEndpoints.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiEndpoints.receiveTimeout,
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    // Yellow Color Console Logging & Loader Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _startLoading();
          final sensitive = options.extra['sensitive'] == true;
          if (enableDebugLogging) {
            _printYellow(
              '==================== [DIO REQUEST] ====================',
            );
            _printYellow('🚀 METHOD: ${options.method} | URL: ${options.uri}');
            if (options.headers.isNotEmpty) {
              final safeHeaders = Map<String, dynamic>.from(options.headers)
                ..removeWhere((key, _) => key.toLowerCase() == 'authorization');
              _printYellow('📋 HEADERS: $safeHeaders');
            }
            if (options.data != null) {
              _printYellow(
                sensitive
                    ? '📦 PAYLOAD: [REDACTED]'
                    : '📦 PAYLOAD: ${options.data}',
              );
            }
            _printYellow(
              '=======================================================',
            );
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _stopLoading();
          final sensitive = response.requestOptions.extra['sensitive'] == true;
          if (enableDebugLogging) {
            _printYellow(
              '==================== [DIO RESPONSE] ===================',
            );
            _printYellow(
              '✅ STATUS: ${response.statusCode} | URL: ${response.requestOptions.uri}',
            );
            _printYellow(
              sensitive ? '📄 DATA: [REDACTED]' : '📄 DATA: ${response.data}',
            );
            _printYellow(
              '=======================================================',
            );
          }
          return handler.next(response);
        },
        onError: (DioException err, handler) {
          _stopLoading();
          final sensitive = err.requestOptions.extra['sensitive'] == true;
          if (enableDebugLogging) {
            _printYellow(
              '==================== [DIO ERROR] ======================',
            );
            _printYellow(
              '⚠️ STATUS: ${err.response?.statusCode ?? 'NETWORK/TIMEOUT'} | URL: ${err.requestOptions.uri}',
            );
            _printYellow('❌ MESSAGE: ${err.message}');
            if (err.response?.data != null && !sensitive) {
              _printYellow('📄 ERROR DATA: ${err.response?.data}');
            } else if (err.response?.data != null) {
              _printYellow('📄 ERROR DATA: [REDACTED]');
            }
            _printYellow(
              '=======================================================',
            );
          }
          return handler.next(err);
        },
      ),
    );
  }

  /// Prints to debug console in Bright Yellow ANSI color (\x1B[33m...\x1B[0m)
  static void _printYellow(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[33m$message\x1B[0m');
    }
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

/// Optional reusable Widget that automatically displays a loading indicator overlay
/// when any Dio network request is in progress.
class GlobalDioLoadingOverlay extends StatelessWidget {
  final Widget child;

  const GlobalDioLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: DioClient.isLoading,
          builder: (context, loading, _) {
            if (!loading) return const SizedBox.shrink();
            return Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
