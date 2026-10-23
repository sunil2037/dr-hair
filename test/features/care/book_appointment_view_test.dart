import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dr_hair/features/care/data/services/care_notification_service.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/care/presentation/views/coach_booking_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Book In-Clinic Physical Appointment View Tests', () {
    late SharedPreferences prefs;
    late CareNotificationService notificationService;
    late CareCubit careCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      notificationService = CareNotificationService(prefs);
      careCubit = CareCubit(notificationService);
    });

    tearDown(() {
      careCubit.close();
    });

    Widget createTestApp(Widget child) {
      return BlocProvider<CareCubit>.value(
        value: careCubit,
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('renders In-Clinic Physical Appointment screen with clinic centers, doctor carousel, and interactive calendar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Title & Hero In-Clinic header
      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('In-Clinic Physical Appointment'), findsOneWidget);
      expect(find.text('60x Dermoscopy'), findsOneWidget);
      expect(find.text('Physical Exam'), findsOneWidget);
      expect(find.text('In-Clinic Only'), findsOneWidget);

      // Section headers
      expect(find.text('1. SELECT CLINIC CENTRE'), findsOneWidget);
      expect(find.text('2. CLINICAL EXAMINATION TYPE'), findsOneWidget);
      expect(find.text('3. SELECT ATTENDING DOCTOR'), findsOneWidget);
      expect(find.text('4. SELECT APPOINTMENT DATE'), findsOneWidget);
      expect(find.text('5. SELECT TIME SLOT'), findsOneWidget);

      // Clinic branches visible
      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Delhi NCR'), findsOneWidget);

      // Specialists visible
      expect(find.text('Dr. Priya Verma'), findsWidgets);
      expect(find.text('Dr. Arvind Mehta'), findsOneWidget);

      // Calendar legend visible
      expect(find.text('Available Date'), findsOneWidget);
      expect(find.text('Closed / Sunday'), findsOneWidget);
    });

    testWidgets('allows selecting clinic center, examination type, calendar date, and time slot', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Switch clinic center to Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      // Switch clinical examination type
      await tester.tap(find.text('In-Clinic Follow-up & Progress Scan (20m)'));
      await tester.pumpAndSettle();

      // Select afternoon slot
      await tester.ensureVisible(find.text('02:00 PM'));
      await tester.tap(find.text('02:00 PM'));
      await tester.pumpAndSettle();

      // Select symptom chip
      await tester.ensureVisible(find.text('Scalp Inflammation'));
      await tester.tap(find.text('Scalp Inflammation'));
      await tester.pumpAndSettle();

      // Verify button is ready
      expect(find.text('Confirm In-Clinic Appointment'), findsOneWidget);
    });

    testWidgets('confirms in-clinic appointment and displays in-person visit details in bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      final initialBookingsCount = careCubit.state.coachBookings.length;

      // Tap Confirm Appointment button
      await tester.ensureVisible(find.text('Confirm In-Clinic Appointment'));
      await tester.tap(find.text('Confirm In-Clinic Appointment'));
      await tester.pumpAndSettle();

      // Verify bottom sheet modal
      expect(find.text('Appointment Confirmed!'), findsOneWidget);
      expect(find.text('In-Clinic Visit'), findsOneWidget);
      expect(find.text('Add to Calendar'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Cubit should have added a new booking
      expect(careCubit.state.coachBookings.length, initialBookingsCount + 1);

      // Close bottom sheet
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Appointment Confirmed!'), findsNothing);
    });

    testWidgets('scheduled clinic appointments display directions dialog and permit cancellation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Existing booking in initial state is an in-clinic appointment
      expect(find.text('Clinic Directions'), findsOneWidget);

      // Tap Clinic Directions
      await tester.tap(find.text('Clinic Directions'));
      await tester.pumpAndSettle();

      expect(find.text('Get Directions'), findsOneWidget);

      // Close directions dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Appointment?'), findsOneWidget);
      await tester.tap(find.text('Cancel Booking'));
      await tester.pumpAndSettle();

      // Status should update to Cancelled
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });
}
