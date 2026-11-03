import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_cubit.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_view.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/auth/presentation/views/complete_profile_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'fake_auth_repository.dart';

void main() {
  group('CompleteProfileView & CompleteProfileBottomSheet Tests', () {
    testWidgets(
      'CompleteProfileView renders avatar upload, required name, optional fields, and pinned button without signout or verified card',
      (tester) async {
        final repo = FakeAuthRepository();
        final cubit = AuthCubit(repository: repo);
        cubit.emit(const AuthState(phoneNumber: '9876543210'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>.value(
              value: cubit,
              child: const CompleteProfileView(),
            ),
          ),
        );

        // Header and form fields
        expect(find.text('Complete your profile'), findsOneWidget);
        expect(find.text('Tell us a little about yourself'), findsOneWidget);

        // Verification card and signout button should NOT exist
        expect(find.text('Your sign-in is verified'), findsNothing);
        expect(find.text('Sign out'), findsNothing);

        // Photo upload / Avatar
        expect(find.byIcon(LucideIcons.camera), findsOneWidget);
        expect(find.text('Upload photo (optional)'), findsOneWidget);

        // Field labels
        expect(find.text('Full name *'), findsOneWidget);
        expect(find.text('Age (optional)'), findsOneWidget);
        expect(find.text('Gender (optional)'), findsOneWidget);
        expect(find.text('City (optional)'), findsOneWidget);
        expect(find.text('Occupation (optional)'), findsOneWidget);

        // Pinned bottom button
        expect(find.text('Save & Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'Full name is required; other fields can be skipped when saving profile',
      (tester) async {
        final repo = FakeAuthRepository();
        final cubit = AuthCubit(repository: repo);
        cubit.emit(const AuthState(phoneNumber: '9876543210'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>.value(
              value: cubit,
              child: const CompleteProfileView(),
            ),
          ),
        );

        // 1. Tapping Save & Continue with empty name triggers validation error
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your full name'), findsOneWidget);

        // 2. Enter full name only (leaving age, gender, city, occupation blank)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name *'),
          'Aarav Sharma',
        );
        await tester.pumpAndSettle();

        // 3. Save & Continue succeeds
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your full name'), findsNothing);
        expect(cubit.state.user?.name, 'Aarav Sharma');
      },
    );

    testWidgets(
      'CompleteProfileBottomSheet enforces age and gender when requireAgeAndGender is true',
      (tester) async {
        final repo = FakeAuthRepository();
        final cubit = AuthCubit(repository: repo);
        final initialUser = UserModel(
          id: 'user_1',
          name: 'Priya Verma',
          emailOrPhone: '9876543210',
          phone: '9876543210',
          patientId: 'DHP0099',
        );
        cubit.emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: initialUser,
            phoneNumber: '9876543210',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>.value(
              value: cubit,
              child: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => CompleteProfileBottomSheet.show(
                        context,
                        requireAgeAndGender: true,
                        title: 'Clinical Consultation Profile',
                      ),
                      child: const Text('Open Sheet'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Bottom sheet headers
        expect(find.text('Clinical Consultation Profile'), findsOneWidget);
        expect(find.text('Age *'), findsOneWidget);
        expect(find.text('Gender *'), findsOneWidget);

        // Tapping Save without filling Age and Gender should fail validation
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your age'), findsOneWidget);
        expect(find.text('Please select your gender'), findsOneWidget);

        // Fill Age & select Gender
        await tester.ensureVisible(find.widgetWithText(TextFormField, 'Age *'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Age *'),
          '29',
        );

        final genderDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(genderDropdown);
        await tester.tap(genderDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Female').last);
        await tester.pumpAndSettle();

        // Submit successfully
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        expect(cubit.state.user?.age, 29);
        expect(cubit.state.user?.gender, 'Female');
      },
    );

    testWidgets(
      'ClinicAppointmentView triggers CompleteProfileBottomSheet before booking physical appointment if age and gender are missing',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = FakeAuthRepository();
        final cubit = AuthCubit(repository: repo);
        // User with name, but without age or gender
        final userWithoutAgeGender = UserModel(
          id: 'user_pat_1',
          name: 'Rahul Sen',
          emailOrPhone: '9876543210',
          phone: '9876543210',
          patientId: 'DHP0055',
        );
        cubit.emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: userWithoutAgeGender,
            phoneNumber: '9876543210',
          ),
        );

        final cache = AppLocalCache.inMemory();
        final appointmentCubit = ClinicAppointmentCubit(cache: cache);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: cubit),
              BlocProvider<ClinicAppointmentCubit>.value(
                value: appointmentCubit,
              ),
            ],
            child: const MaterialApp(home: ClinicAppointmentView()),
          ),
        );

        // Verify ClinicAppointmentView is displayed
        expect(find.text('In-Clinic Appointment'), findsOneWidget);

        // Tap sitting slot picker container
        await tester.tap(find.text('Tap to choose date & sitting slot'));
        await tester.pumpAndSettle();

        // AppointmentDatePickerBottomSheet should appear
        expect(find.text('Select Clinic Visit Slot'), findsOneWidget);

        // Tap day 20 on calendar to choose a guaranteed future date
        await tester.tap(find.text('20').first);
        await tester.pumpAndSettle();

        // Tap sitting slot '11:00 AM' and confirm
        await tester.tap(find.text('11:00 AM'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Slot'));
        await tester.pumpAndSettle();

        // Now on ClinicAppointmentView, tap Proceed to Book & Pay
        final confirmBtn = find.text('Proceed to Book & Pay (₹500)');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // CompleteProfileBottomSheet MUST appear because age and gender are missing!
        expect(find.text('Complete your profile'), findsOneWidget);
        expect(
          find.text(
            'Age and gender are required before booking an in-clinic consultation.',
          ),
          findsOneWidget,
        );
        expect(find.text('Age *'), findsOneWidget);
        expect(find.text('Gender *'), findsOneWidget);

        // Fill Age & Gender inside the sheet
        await tester.ensureVisible(find.widgetWithText(TextFormField, 'Age *'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Age *'),
          '34',
        );

        final genderDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(genderDropdown);
        await tester.tap(genderDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Male').last);
        await tester.pumpAndSettle();

        // Save & Continue
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        // Profile should now be updated in cubit
        expect(cubit.state.user?.age, 34);
        expect(cubit.state.user?.gender, 'Male');

        // AppointmentPaymentSheet appears to confirm consultation fee checkout
        expect(find.text('Consultation Checkout'), findsOneWidget);
        await tester.tap(find.text('Pay ₹500 & Confirm Visit'));
        await tester.pumpAndSettle();

        // And the in-clinic appointment request should now be saved!
        expect(
          appointmentCubit.forPatient(cubit.state.user!.patientId),
          hasLength(1),
        );
      },
    );
  });
}
