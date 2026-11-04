import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/care_models.dart';

class PatientDietPlanResponse {
  final List<DietMeal> meals;
  final String treatmentName;
  final String doctorName;

  const PatientDietPlanResponse({
    required this.meals,
    this.treatmentName = 'Personalized Nutrition Plan',
    this.doctorName = 'Dr. Hair Clinical Team',
  });
}

class PatientDietApi {
  final Dio _dio;

  PatientDietApi({Dio? dio})
      : _dio = dio ?? DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  Future<PatientDietPlanResponse> getPatientDietPlan(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.patientDietPlan,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final rawMeals = data['diet_meals'] as List<dynamic>? ?? [];
    final meals = rawMeals
        .whereType<Map<String, dynamic>>()
        .map((m) => DietMeal.fromJson(m))
        .toList();

    return PatientDietPlanResponse(
      meals: meals,
      treatmentName:
          data['treatment_name'] as String? ?? 'Personalized Nutrition Plan',
      doctorName: data['doctor_name'] as String? ?? 'Dr. Hair Clinical Team',
    );
  }
}
