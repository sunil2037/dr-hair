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
    try {
      final response = await dioClient.dio.get(ApiEndpoints.services);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // In development or when API is offline, return curated mock data for Dr Hair
    }

    // Curated Dr Hair clinic treatment services
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    return const [
      ServiceModel(
        id: '1',
        title: 'Hair Loss Consultation & Trichoscopy',
        description: 'Comprehensive digital scalp analysis by expert dermatologists to determine root cause.',
        imageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80',
        rating: 4.9,
        reviewsCount: 320,
        price: '\$49',
      ),
      ServiceModel(
        id: '2',
        title: 'PRP Hair Follicle Therapy',
        description: 'Platelet-Rich Plasma micro-injections stimulating natural hair regrowth and thickness.',
        imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=80',
        rating: 4.8,
        reviewsCount: 215,
        price: '\$199',
      ),
      ServiceModel(
        id: '3',
        title: 'FUE Advanced Hair Transplant',
        description: 'Minimally invasive follicular unit extraction with natural hairline design and fast recovery.',
        imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
        rating: 4.95,
        reviewsCount: 480,
        price: 'From \$1,499',
      ),
      ServiceModel(
        id: '4',
        title: 'Low-Level Laser Light Therapy',
        description: 'Painless red-light stimulation for cellular energy & reversing follicle miniaturization.',
        imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=600&q=80',
        rating: 4.7,
        reviewsCount: 140,
        price: '\$89',
      ),
    ];
  }
}
