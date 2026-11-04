import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/media/data/media_upload_api.dart';
import '../../../core/network/dio_client.dart';

class PatientProgressApi {
  final Dio _dio;
  late final MediaUploadApi _mediaUploadApi = MediaUploadApi(dio: _dio);

  PatientProgressApi({Dio? dio})
    : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<void> createCheckIn({
    required String token,
    required String id,
    required DateTime date,
    required Map<String, String> photoPaths,
    required String scalpRegion,
    required String sheddingLevel,
    required String notes,
    required int densityRating,
  }) async {
    final entries = photoPaths.entries.toList();
    final files = await Future.wait(
      entries.map((entry) async {
        return MultipartFile.fromFile(
          entry.value,
          filename: File(entry.value).uri.pathSegments.last,
        );
      }),
    );
    final uploaded = await _mediaUploadApi.uploadFiles(
      token: token,
      purpose: 'progress',
      files: files,
    );
    final photos = List<Map<String, dynamic>>.generate(entries.length, (index) {
      final asset = uploaded[index];
      if (asset['resource_type'] != 'image' ||
          asset['public_id'] is! String ||
          asset['url'] is! String) {
        throw const FormatException(
          'Progress image upload returned invalid asset data.',
        );
      }
      return {
        'angle': entries[index].key,
        'public_id': asset['public_id'],
        'url': asset['url'],
        'file_name': File(entries[index].value).uri.pathSegments.last,
        'mime_type': asset['mime_type'] ?? 'image/jpeg',
        'bytes': asset['bytes'] ?? 0,
      };
    });
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.patientProgressCheckins,
      data: {
        'id': id,
        'date': date.toIso8601String(),
        'scalp_region': scalpRegion,
        'shedding_level': sheddingLevel,
        'notes': notes,
        'density_rating': densityRating,
        'photos': photos,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<Map<String, dynamic>>> listCheckIns({
    required String token,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.patientProgressCheckins,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data?['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> deleteCheckIn({
    required String token,
    required String checkInId,
  }) async {
    await _dio.delete<Map<String, dynamic>>(
      ApiEndpoints.patientProgressCheckinById(checkInId),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
