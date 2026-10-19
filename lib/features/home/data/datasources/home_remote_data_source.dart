import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/service_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<ServiceModel>> fetchServices();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ServiceModel>> fetchServices() async {
    final response = await dioClient.dio.get(ApiEndpoints.services);
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw const FormatException('The services response was not a list.');
  }
}
