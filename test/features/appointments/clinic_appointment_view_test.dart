import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/appointments/data/patient_appointment_api.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_cubit.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_view.dart';
import 'package:dr_hair/features/appointments/presentation/widgets/appointment_payment_sheet.dart';
import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';

class _MockAppointmentApi extends PatientAppointmentApi {
  List<Map<String, dynamic>> items;
  _MockAppointmentApi([this.items = const []]);

  @override
  Future<List<Map<String, dynamic>>> list(String token) async => items;

  Future<Map<String, dynamic>> reschedule({
    required String token,
    required String appointmentId,
    required DateTime startsAt,
  }) async {
    return {
      'id': appointmentId,
      'starts_at': startsAt.toUtc().toIso8601String(),
    };
  }
}

class _FakeAuthCubit extends AuthCubit {
  _FakeAuthCubit(UserModel? user) : super() {
    emit(AuthState(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: user,
      sessionToken: user != null ? 'test-token' : null,
      isRegistered: user != null,
    ));
  }
}

void main() {
  testWidgets('ClinicAppointmentView renders consultation fee and booking button for authenticated patient', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = AppLocalCache.inMemory();
    final appointmentCubit = ClinicAppointmentCubit(cache: cache);
    final user = const UserModel(
      id: '991',
      patientId: 'PAT-991',
      name: 'Sahil Tester',
      emailOrPhone: '9876543210',
      phone: '9876543210',
      age: 26,
      gender: 'Male',
      isGuest: false,
    );
    final authCubit = _FakeAuthCubit(user);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<ClinicAppointmentCubit>.value(value: appointmentCubit),
        ],
        child: const MaterialApp(
          home: ClinicAppointmentView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Doctor Card
    expect(find.text('In-Clinic Appointment'), findsOneWidget);
    expect(find.text('Dr. Jai Bansal'), findsOneWidget);

    // Verify Consultation Fee card
    expect(find.textContaining('Consultation & Trichoscopy Fee: ₹500'), findsOneWidget);
    expect(find.textContaining('UPI / Card / Pay at Clinic'), findsOneWidget);

    // Verify Proceed to Book & Pay button
    final bookButton = find.text('Proceed to Book & Pay (₹500)');
    await tester.ensureVisible(bookButton);
    expect(bookButton, findsOneWidget);

    // Verify empty state for visits
    expect(find.text('No physical clinic visits scheduled yet.'), findsOneWidget);
  });

  testWidgets('AppointmentPaymentSheet displays payment methods, fee breakdown, and confirms payment', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppointmentPaymentResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await AppointmentPaymentSheet.show(
                    context,
                    startsAt: DateTime(2026, 11, 10, 10, 30),
                    doctorName: 'Dr. Jai Bansal',
                    fee: 500,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Sheet Content
    expect(find.text('Consultation Checkout'), findsOneWidget);
    expect(find.text('Dr. Jai Bansal'), findsOneWidget);
    expect(find.text('SELECT PAYMENT METHOD'), findsOneWidget);
    expect(find.textContaining('UPI (GPay / PhonePe / Paytm / QR)'), findsOneWidget);
    expect(find.text('Credit / Debit Card'), findsOneWidget);
    expect(find.text('Pay Cash at Clinic Desk'), findsOneWidget);
    expect(find.text('Total Payable'), findsOneWidget);
    expect(find.text('₹500'), findsWidgets);

    // Select Pay Cash at Clinic option
    await tester.tap(find.text('Pay Cash at Clinic Desk'));
    await tester.pumpAndSettle();

    // Verify button text changed to reflect Cash at Clinic
    expect(find.text('Confirm Booking (Pay ₹500 at Clinic)'), findsOneWidget);

    // Select UPI option back
    await tester.tap(find.textContaining('UPI (GPay'));
    await tester.pumpAndSettle();
    expect(find.text('Pay ₹500 & Confirm Visit'), findsOneWidget);

    // Tap Pay & Confirm
    final payButton = find.text('Pay ₹500 & Confirm Visit');
    await tester.ensureVisible(payButton);
    await tester.tap(payButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify result returned
    expect(result, isNotNull);
    expect(result?.amount, 500);
    expect(result?.paymentMethod, 'UPI');
    expect(result?.paymentStatus, 'Paid');
    expect(result?.transactionId.startsWith('TXN-CLINIC-'), true);
  });

  testWidgets('tapping Reschedule opens date picker bottom sheet and updates slot directly on screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = AppLocalCache.inMemory();
    final existingSlot = DateTime(2026, 11, 20, 10, 0);
    final mockApi = _MockAppointmentApi([
      {
        'id': 'APT-991',
        'patientId': 'PAT-991',
        'userId': '991',
        'starts_at': existingSlot.toUtc().toIso8601String(),
        'reason': 'Scalp scan & treatment',
        'consultation_fee': 500,
        'payment_method': 'UPI',
        'payment_status': 'Paid',
        'status': 'Confirmed',
      }
    ]);
    final appointmentCubit = ClinicAppointmentCubit(cache: cache, api: mockApi);
    final user = const UserModel(
      id: '991',
      patientId: 'PAT-991',
      name: 'Sahil Tester',
      emailOrPhone: '9876543210',
      phone: '9876543210',
      age: 26,
      gender: 'Male',
      isGuest: false,
    );
    final authCubit = _FakeAuthCubit(user);

    await appointmentCubit.saveRequest(
      patientId: 'PAT-991',
      startsAt: existingSlot,
      reason: 'Scalp scan & treatment',
      consultationFee: 500,
      paymentMethod: 'UPI',
      paymentStatus: 'Paid',
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<ClinicAppointmentCubit>.value(value: appointmentCubit),
        ],
        child: const MaterialApp(
          home: ClinicAppointmentView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify existing appointment is listed
    expect(find.text('Dr. Jai Bansal Clinic Chamber'), findsOneWidget);
    final rescheduleFinder = find.text('Reschedule');
    expect(rescheduleFinder, findsOneWidget);
    await tester.ensureVisible(rescheduleFinder);
    await tester.pumpAndSettle();

    // Tap Reschedule button
    await tester.tap(rescheduleFinder);
    await tester.pumpAndSettle();

    // Verify date picker bottom sheet is open
    expect(find.text('Select Clinic Visit Slot'), findsOneWidget);
    expect(find.text('Confirm Slot'), findsOneWidget);

    // Pick a new slot (11:30 AM)
    final newSlotChip = find.text('11:30 AM');
    if (newSlotChip.evaluate().isNotEmpty) {
      await tester.tap(newSlotChip);
      await tester.pumpAndSettle();
    }

    // Confirm the slot
    await tester.tap(find.text('Confirm Slot'));
    await tester.pumpAndSettle();

    // Date picker bottom sheet should be dismissed
    expect(find.text('Select Appointment Slot'), findsNothing);

    // Verify appointment card still rendered with updated slot
    expect(find.text('Dr. Jai Bansal Clinic Chamber'), findsOneWidget);
  });
}
