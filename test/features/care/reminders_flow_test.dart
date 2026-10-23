import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dr_hair/features/care/data/services/care_notification_service.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/care/presentation/views/reminders_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reminders Feature Tests', () {
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

    testWidgets('renders scheduled reminders and permits toggling', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const RemindersView()));
      await tester.pumpAndSettle();

      expect(find.text('Care Reminders'), findsOneWidget);
      expect(find.text('Morning Supplement'), findsOneWidget);
      expect(find.text('Evening Topical Booster'), findsOneWidget);

      // Verify toggle switch
      final switches = find.byType(CupertinoSwitch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Check state updated in cubit
      expect(careCubit.state.reminders.first.isEnabled, isFalse);
    });

    testWidgets('allows marking reminder done for today', (tester) async {
      await tester.pumpWidget(createTestApp(const RemindersView()));
      await tester.pumpAndSettle();

      final markDoneButtons = find.text('Mark Done');
      expect(markDoneButtons, findsWidgets);

      await tester.tap(markDoneButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsWidgets);
      expect(careCubit.state.reminders.first.isCompleted, isTrue);
    });

    testWidgets('can snooze a reminder for 15 minutes', (tester) async {
      await tester.pumpWidget(createTestApp(const RemindersView()));
      await tester.pumpAndSettle();

      final snoozeButtons = find.byTooltip('Snooze reminder');
      expect(snoozeButtons, findsWidgets);

      await tester.tap(snoozeButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('15 Minutes'), findsOneWidget);
      await tester.tap(find.text('15 Minutes'));
      await tester.pumpAndSettle();

      expect(find.text('Snoozed'), findsWidgets);
      expect(careCubit.state.reminders.first.isSnoozed, isTrue);
    });

    testWidgets(
      'shows empty state when all reminders are deleted and can add a new one',
      (tester) async {
        // Clear all reminders in cubit
        final ids = careCubit.state.reminders.map((r) => r.id).toList();
        for (final id in ids) {
          careCubit.deleteReminder(id);
        }

        await tester.pumpWidget(createTestApp(const RemindersView()));
        await tester.pumpAndSettle();

        expect(find.text('No Care Reminders Scheduled'), findsOneWidget);
        expect(find.text('Add First Reminder'), findsOneWidget);

        // Open add reminder bottom sheet
        await tester.tap(find.text('Add First Reminder'));
        await tester.pumpAndSettle();

        expect(find.text('Add Care Reminder'), findsOneWidget);
        expect(find.text('Reminder Title'), findsOneWidget);

        // Try saving without title - validates error
        await tester.tap(find.text('Save Reminder'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a reminder title'), findsOneWidget);

        // Enter title and pick Oral Supplement
        await tester.enterText(
          find.byType(TextField).first,
          'Biotin Post-Lunch',
        );
        await tester.tap(find.text('Oral Supplement'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save Reminder'));
        await tester.pumpAndSettle();

        expect(find.text('Biotin Post-Lunch'), findsOneWidget);
        expect(careCubit.state.reminders.length, 1);
      },
    );

    testWidgets(
      'handles notification permission denied state and recovery advice',
      (tester) async {
        // Set permission to denied
        await careCubit.requestNotificationPermission(simulateDenial: true);

        await tester.pumpWidget(createTestApp(const RemindersView()));
        await tester.pumpAndSettle();

        expect(find.text('Notifications Disabled'), findsOneWidget);
        expect(find.text('How to enable in Settings →'), findsOneWidget);

        await tester.tap(find.text('How to enable in Settings →'));
        await tester.pumpAndSettle();

        expect(find.text('Enable Notifications in Settings'), findsOneWidget);
        expect(find.text('I Enabled It'), findsOneWidget);

        await tester.tap(find.text('I Enabled It'));
        await tester.pumpAndSettle();

        expect(
          careCubit.state.notificationPermissionStatus,
          NotificationPermissionStatus.granted,
        );
      },
    );

    test('persists reminders across app restart via SharedPreferences', () async {
      // Add custom reminder
      careCubit.addReminder(
        title: 'Ketoconazole 2% Wash',
        subtitle: 'Medicated Wash · Wed, Sat',
        time: const TimeOfDay(hour: 10, minute: 30),
        frequency: 'Weekly',
        treatmentType: 'Medicated Wash',
        repeatDays: [3, 6],
        notes: 'Leave on scalp for 5 minutes',
      );

      // Create new cubit simulating app restart with the same prefs
      final restartedCubit = CareCubit(notificationService);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final loaded = restartedCubit.state.reminders.firstWhere(
        (r) => r.title == 'Ketoconazole 2% Wash',
      );
      expect(loaded.title, 'Ketoconazole 2% Wash');
      expect(loaded.treatmentType, 'Medicated Wash');
      expect(loaded.repeatDays, [3, 6]);
      expect(loaded.notes, 'Leave on scalp for 5 minutes');

      restartedCubit.close();
    });
  });
}
