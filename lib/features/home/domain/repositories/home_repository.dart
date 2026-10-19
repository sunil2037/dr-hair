import '../entities/service_entity.dart';

abstract class HomeRepository {
  Future<List<ServiceEntity>> getServices();
}
