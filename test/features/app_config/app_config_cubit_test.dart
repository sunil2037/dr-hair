import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/app_config/data/app_config_repository.dart';
import 'package:dr_hair/features/app_config/presentation/viewmodels/app_config_cubit.dart';
import 'package:dr_hair/features/app_config/presentation/viewmodels/app_config_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfigCubit & AppConfigRepository', () {
    test('initializes with default features when cache is empty', () {
      final cache = AppLocalCache.inMemory();
      final repository = AppConfigRepository(cache: cache);
      final cubit = AppConfigCubit(repository: repository);

      expect(cubit.state.features['shop'], isTrue);
      expect(cubit.state.features['clinic_appointment'], isTrue);
      expect(cubit.state.features['assessment'], isTrue);
      expect(cubit.state.features['videos'], isTrue);
      expect(cubit.state.features['reviews'], isTrue);
      expect(cubit.state.features['routine'], isTrue);
      expect(cubit.state.features['reminders'], isTrue);
      expect(cubit.state.features['reports'], isTrue);
      expect(cubit.isFeatureEnabled('shop'), isTrue);
    });

    test('isFeatureEnabled returns false when explicitly disabled', () {
      final state = const AppConfigState(
        features: {
          'shop': false,
          'clinic_appointment': true,
        },
      );

      expect(state.isFeatureEnabled('shop'), isFalse);
      expect(state.isFeatureEnabled('clinic_appointment'), isTrue);
      expect(state.isFeatureEnabled('unknown_key', defaultValue: false), isFalse);
    });
  });
}
