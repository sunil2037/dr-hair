import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_services_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetServicesUseCase getServicesUseCase;

  HomeCubit({required this.getServicesUseCase}) : super(const HomeState());

  Future<void> loadServices() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final services = await getServicesUseCase();
      emit(state.copyWith(
        status: HomeStatus.success,
        services: services,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void refresh() {
    loadServices();
  }
}
