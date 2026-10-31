import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class PatientAppointmentApi {
  final Dio _dio;

  PatientAppointmentApi({Dio? dio})
    : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Options _authorized(String token) => Options(
    headers: {'Authorization': 'Bearer $token'},
  );

  Future<List<Map<String, dynamic>>> list(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/patient/appointments',
      options: _authorized(token),
    );
    final data = response.data?['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) throw const FormatException('Appointment list response is invalid.');
    return items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> create({
    required String token,
    required DateTime startsAt,
    required String reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/patient/appointments',
      data: {'starts_at': startsAt.toUtc().toIso8601String(), 'reason': reason},
      options: _authorized(token),
    );
    return _readData(response.data);
  }

  Future<Map<String, dynamic>> update({
    required String token,
    required String appointmentId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/patient/appointments/${Uri.encodeComponent(appointmentId)}',
      data: data,
      options: _authorized(token),
    );
    return _readData(response.data);
  }

  Map<String, dynamic> _readData(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) throw const FormatException('Appointment response is invalid.');
    return Map<String, dynamic>.from(data);
  }
}
