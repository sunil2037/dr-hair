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
            enableDebugLogging: true,
          );

  Future<Map<String, dynamic>> getClinicalRecord(String accessToken) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.patientClinicalRecord,
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
      ApiEndpoints.patientReportDownload(reportId),
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

  Future<List<Map<String, dynamic>>> getRoutineSteps(String accessToken) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      ApiEndpoints.patientRoutineSteps,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final data = response.data?['data'];
    final steps = data is Map ? data['routine_steps'] : null;
    if (steps is List) {
      return steps
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> addRoutineStep({
    required String accessToken,
    required String title,
    required String subtitle,
    required String category,
    required String timeOfDay,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      ApiEndpoints.patientRoutineSteps,
      data: {
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'time_of_day': timeOfDay,
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final data = response.data?['data'];
    final steps = data is Map ? data['routine_steps'] : null;
    if (steps is List) {
      return steps
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> deleteRoutineStep({
    required String accessToken,
    required int stepIndex,
  }) async {
    final response = await _client.dio.delete<Map<String, dynamic>>(
      ApiEndpoints.patientRoutineStepByIndex(stepIndex),
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final data = response.data?['data'];
    final steps = data is Map ? data['routine_steps'] : null;
    if (steps is List) {
      return steps
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }
}
