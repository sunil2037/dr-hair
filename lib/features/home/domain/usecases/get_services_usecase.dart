import '../entities/service_entity.dart';
import '../repositories/home_repository.dart';

class GetServicesUseCase {
  final HomeRepository repository;

  GetServicesUseCase({required this.repository});

  Future<List<ServiceEntity>> call() async {
    return await repository.getServices();
  }
}
