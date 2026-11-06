import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/app_local_cache.dart';

/// Repository that handles fetching, caching, and serving live app feature flags.
class AppConfigRepository {
  final DioClient _dioClient;
  final AppLocalCache _cache;

  AppConfigRepository({DioClient? dioClient, AppLocalCache? cache})
      : _dioClient = dioClient ?? DioClient(),
        _cache = cache ?? AppLocalCache.instance;

  static const String _cacheKey = 'cached_feature_flags_v1';

  static const Map<String, bool> defaultFeatures = <String, bool>{
    'shop': true,
    'clinic_appointment': true,
    'assessment': true,
    'videos': true,
    'reviews': true,
    'routine': true,
    'reminders': true,
    'reports': true,
  };

  /// Returns cached flags instantly from local storage for 0ms cold-start latency.
  Map<String, bool> getCachedFeatures() {
    try {
      final cachedJson = _cache.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map) {
          final result = Map<String, bool>.from(defaultFeatures);
          decoded.forEach((key, value) {
            result[key.toString()] = value == true;
          });
          return result;
        }
      }
    } catch (e) {
      debugPrint('Failed to decode cached feature flags: $e');
    }
    return defaultFeatures;
  }

  /// Synchronizes with backend `/api/v1/app/config` and updates local cache.
  Future<Map<String, bool>> fetchAppFeatures() async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.appConfig,
      );
      final body = response.data;
      if (body != null && body['data'] != null) {
        final featuresData = body['data']['features'];
        if (featuresData is Map) {
          final result = Map<String, bool>.from(defaultFeatures);
          featuresData.forEach((key, value) {
            result[key.toString()] = value == true;
          });
          await _cache.put(_cacheKey, jsonEncode(result));
          return result;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch app config: $e');
    }
    return getCachedFeatures();
  }
}

