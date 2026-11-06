import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_config_repository.dart';
import 'app_config_state.dart';

/// Cubit managing dynamic feature availability across the app.
class AppConfigCubit extends Cubit<AppConfigState> {
  final AppConfigRepository _repository;

  AppConfigCubit({AppConfigRepository? repository})
      : _repository = repository ?? AppConfigRepository(),
        super(
          AppConfigState(
            features: (repository ?? AppConfigRepository()).getCachedFeatures(),
          ),
        ) {
    loadConfig();
  }

  /// Fetches live configuration from the server and updates state/cache.
  Future<void> loadConfig() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final updatedFeatures = await _repository.fetchAppFeatures();
      emit(state.copyWith(features: updatedFeatures, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Convenience helper to check if a feature is enabled.
  bool isFeatureEnabled(String key, {bool defaultValue = true}) {
    return state.isFeatureEnabled(key, defaultValue: defaultValue);
  }
}

