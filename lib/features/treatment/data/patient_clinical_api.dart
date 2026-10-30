import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class PatientClinicalApi {
  final DioClient _client;

  PatientClinicalApi({DioClient? client})
    : _client =
          client ??
          DioClient(
            baseUrl: ApiEndpoints.backendBaseUrl,
            enableDebugLogging: false,
          );

  Future<Map<String, dynamic>> getClinicalRecord(String accessToken) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/v1/patient/clinical-record',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'The patient clinical record response is invalid.',
      );
    }
    return data;
  }

  Future<Uri> getReportDownloadUri({
    required String accessToken,
    required String reportId,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/v1/patient/reports/${Uri.encodeComponent(reportId)}/download',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final envelope = response.data;
    final data = envelope?['data'];
    final url = data is Map ? data['url'] : null;
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('The report download link is invalid.');
    }
    return uri;
  }
}
