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
      '/api/v1/patient/progress-checkins',
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
}
