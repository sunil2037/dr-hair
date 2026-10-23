import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dr_hair/features/care/data/services/care_notification_service.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/care/presentation/views/coach_booking_view.dart';
import 'package:dr_hair/core/widgets/custom_animated_dropdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Book In-Clinic Physical Appointment - Jaipur Clinic Tests', () {
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

    testWidgets('renders clinic card, specialists with tap-to-book, and nested scroll tab bar filter', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Top Clinic Detail Card with exact Jaipur location
      expect(find.text('Dr. Hair Clinic & Hair Restoration Centre'), findsOneWidget);
      expect(find.textContaining('111/398, Vijay Path'), findsOneWidget);
      expect(find.textContaining('Mansarovar, Jaipur, Rajasthan 302020'), findsOneWidget);
      expect(find.text('Open in Google Maps'), findsOneWidget);

      // Section Headers on Main Screen
      expect(find.text('ATTENDING SPECIALISTS'), findsOneWidget);

      // Doctors visible in horizontal cards
      expect(find.text('Dr. Priya Verma'), findsWidgets);
      expect(find.text('Dr. Arvind Mehta'), findsOneWidget);
      expect(find.text('Dr. Sneha Kapoor'), findsOneWidget);

      // Pinned Tab Bar Filter (Upcoming, Attended, Cancelled)
      expect(find.textContaining('Upcoming'), findsWidgets);
      expect(find.textContaining('Attended'), findsWidgets);
      expect(find.textContaining('Cancelled'), findsWidgets);

      // Confirms bottom floating button is removed
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('tapping specialist card opens bottom sheet with ONLY selected doctor details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Tap on Dr. Arvind Mehta's card to open booking sheet
      await tester.tap(find.text('Dr. Arvind Mehta'));
      await tester.pumpAndSettle();

      // Inside bottom sheet
      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Physical Visit · Mansarovar, Jaipur Clinic'), findsOneWidget);

      // ONLY selected attendant details are shown in the bottom sheet
      expect(find.text('Attending Specialist'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Dr. Arvind Mehta'),
        ),
        findsWidgets,
      );
      // Dr. Priya Verma should NOT be shown inside the bottom sheet
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Dr. Priya Verma'),
        ),
        findsNothing,
      );

      // Date & Timing selectors
      expect(find.text('SELECT APPOINTMENT DATE'), findsOneWidget);
      expect(find.text('APPOINTMENT TIME'), findsOneWidget);
      expect(find.byType(CustomAnimatedDropdown<String>), findsOneWidget);

      // Enter optional visit notes
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(
        find.byType(TextField),
        'Suffering from frontal hairline recession and itching.',
      );
      await tester.pumpAndSettle();

      // Confirm button is visible
      expect(find.text('Confirm In-Clinic Appointment'), findsOneWidget);
    });

    testWidgets('confirms in-clinic appointment and displays professional pass with Google & Apple Calendar reminders', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      final initialBookingsCount = careCubit.state.coachBookings.length;

      // Tap on Dr. Priya Verma to open sheet
      await tester.tap(find.text('Dr. Priya Verma').first);
      await tester.pumpAndSettle();

      // Tap Confirm Appointment button inside bottom sheet
      await tester.ensureVisible(find.text('Confirm In-Clinic Appointment'));
      await tester.tap(find.text('Confirm In-Clinic Appointment'));
      await tester.pumpAndSettle();

      // Verify professional confirmation modal
      expect(find.text('Appointment Confirmed!'), findsOneWidget);
      expect(find.text('In-Person Consultation Pass · Jaipur Clinic'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.textContaining('Dr. Hair Clinic & Hair Restoration Centre'), findsWidgets);
      expect(find.textContaining('Mansarovar, Jaipur'), findsWidgets);

      // Google Calendar and Apple Calendar reminder buttons are present
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Apple Calendar'), findsOneWidget);

      // Close confirmation sheet
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Cubit should have added a new booking
      expect(careCubit.state.coachBookings.length, initialBookingsCount + 1);
      expect(find.text('In-Person Consultation Pass · Jaipur Clinic'), findsNothing);
    });

    testWidgets('scheduled clinic visits at Mansarovar clinic show Open in Maps and allow cancel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CoachBookingView()));
      await tester.pumpAndSettle();

      // Initial booking in state has Open in Maps
      expect(find.text('Open in Maps'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Appointment?'), findsOneWidget);
      await tester.tap(find.text('Cancel Booking'));
      await tester.pumpAndSettle();

      // Switch to Cancelled tab
      await tester.tap(find.textContaining('Cancelled').first);
      await tester.pumpAndSettle();

      // Status should update to Cancelled in the Cancelled tab
      expect(find.text('Cancelled'), findsWidgets);
    });
  });
}
