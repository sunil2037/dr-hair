import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../../network/dio_client.dart';

/// Shared client for the single authenticated media upload endpoint.
/// Feature APIs should persist the returned asset metadata with their own data.
class MediaUploadApi {
  final Dio _dio;

  MediaUploadApi({Dio? dio})
    : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<List<Map<String, dynamic>>> uploadFiles({
    required String token,
    required String purpose,
    required List<MultipartFile> files,
  }) async {
    if (files.isEmpty || files.length > 5) {
      throw ArgumentError.value(
        files.length,
        'files',
        'Upload between 1 and 5 files.',
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/upload',
      data: FormData.fromMap({'files': files}),
      options: Options(
        headers: {'Authorization': 'Bearer $token', 'X-Media-Purpose': purpose},
      ),
    );

    final data = response.data?['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List || items.length != files.length) {
      throw const FormatException('Media upload response is invalid.');
    }
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
