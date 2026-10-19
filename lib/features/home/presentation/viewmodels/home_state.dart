import '../../domain/entities/service_entity.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<ServiceEntity> services;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.services = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<ServiceEntity>? services,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      services: services ?? this.services,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
