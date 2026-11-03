import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_hair/core/session/session_coordinator.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_cubit.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/cart_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionCoordinator Tests', () {
    late AuthCubit authCubit;
    late CareCubit careCubit;
    late CartCubit cartCubit;
    late ClinicAppointmentCubit appointmentCubit;
    late HairTestCubit hairTestCubit;
    late SessionCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppLocalCache.instance.clearAll();

      authCubit = AuthCubit();
      careCubit = CareCubit();
      cartCubit = CartCubit();
      appointmentCubit = ClinicAppointmentCubit();
      hairTestCubit = HairTestCubit();

      coordinator = SessionCoordinator.instance;
      coordinator.attach(
        authCubit: authCubit,
        careCubit: careCubit,
        cartCubit: cartCubit,
        appointmentCubit: appointmentCubit,
        hairTestCubit: hairTestCubit,
      );
    });

    tearDown(() {
      coordinator.dispose();
      authCubit.close();
      careCubit.close();
      cartCubit.close();
      appointmentCubit.close();
      hairTestCubit.close();
    });

    test('binds patient on authentication and clears patient-scoped data on sign-out', () async {
      const testUser = UserModel(
        id: '42',
        emailOrPhone: '9876543210',
        name: 'Test Patient',
        phone: '9876543210',
        email: 'patient@example.com',
      );

      // Save some patient-scoped data in cache
      await AppLocalCache.instance.put(
        AppLocalCache.patientKey('42', 'test_key'),
        'patient_value',
      );
      expect(
        AppLocalCache.instance.get(AppLocalCache.patientKey('42', 'test_key')),
        equals('patient_value'),
      );

      // Authenticate
      authCubit.emitForTesting(
        const AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          sessionToken: 'test_token',
        ),
      );

      // Verify sign out clears patient data
      await coordinator.clearPatientSession(
        patientId: '42',
        careCubit: careCubit,
        cartCubit: cartCubit,
        appointmentCubit: appointmentCubit,
        hairTestCubit: hairTestCubit,
      );

      // Patient-scoped cache should now be cleared
      expect(
        AppLocalCache.instance.get(AppLocalCache.patientKey('42', 'test_key')),
        isNull,
      );
    });

    test('handleAccountDeleted flushes patient data and local cache', () async {
      await AppLocalCache.instance.put('has_completed_hair_test', true);
      await AppLocalCache.instance.put('has_skipped_hair_test', true);
      await AppLocalCache.instance.put(
        AppLocalCache.patientKey('42', 'record_key'),
        'clinical_record',
      );

      await coordinator.handleAccountDeleted(
        message: 'Your account has been deleted by clinic administration.',
      );

      expect(AppLocalCache.instance.get('has_completed_hair_test'), isNull);
      expect(AppLocalCache.instance.get('has_skipped_hair_test'), isNull);
    });
  });
}
