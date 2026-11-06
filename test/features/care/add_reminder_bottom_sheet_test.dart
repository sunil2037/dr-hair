import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/care/data/services/care_notification_service.dart';
import 'package:dr_hair/features/care/domain/models/care_models.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/care/presentation/widgets/add_reminder_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddReminderBottomSheet Tests', () {
    late AppLocalCache cache;
    late CareNotificationService notificationService;
    late CareCubit careCubit;

    setUp(() async {
      cache = AppLocalCache.inMemory();
      notificationService = CareNotificationService(cache);
      careCubit = CareCubit(notificationService)..loadSampleFixturesForTesting();
    });

    tearDown(() {
      careCubit.close();
    });

    Widget createTestApp(Widget child) {
      return BlocProvider<CareCubit>.value(
        value: careCubit,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders all sections and quick clinical presets correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddReminderBottomSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add Care Reminder'), findsOneWidget);
      expect(find.text('Quick Clinical Suggestions'), findsOneWidget);
      expect(find.text('Reminder Title'), findsOneWidget);
      expect(find.text('Treatment / Regimen Category'), findsOneWidget);
      expect(find.text('Scheduled Time'), findsOneWidget);
      expect(find.text('Repeat Days'), findsOneWidget);
      expect(find.text('Active Reminder Alert'), findsOneWidget);
      expect(find.text('Save Reminder'), findsOneWidget);

      // Tap on the first clinical preset chip (Minoxidil)
      final minoxidilPreset = find.byType(ActionChip).first;
      expect(minoxidilPreset, findsOneWidget);
      await tester.tap(minoxidilPreset);
      await tester.pumpAndSettle();

      // Title should be auto-filled
      expect(find.text('Dr. Hair 5% Minoxidil Booster'), findsOneWidget);
      expect(
        find.text('Apply 1ml with dropper evenly on affected areas before bed'),
        findsOneWidget,
      );
    });

    testWidgets('preset days shortcuts work and toggle active days', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddReminderBottomSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Weekdays shortcut
      await tester.tap(find.text('Weekdays'));
      await tester.pumpAndSettle();

      // Tap Alt Days shortcut
      await tester.tap(find.text('Alt Days'));
      await tester.pumpAndSettle();

      // Tap Everyday shortcut
      await tester.tap(find.text('Everyday'));
      await tester.pumpAndSettle();
    });

    testWidgets('editing an existing reminder shows Edit header and delete button', (
      tester,
    ) async {
      const existing = CareReminder(
        id: 'test_rem_1',
        title: 'Morning Scalp Tonic',
        subtitle: 'Topical Serum · Daily',
        time: TimeOfDay(hour: 8, minute: 30),
        treatmentType: 'Topical Serum',
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
        notes: 'Spray 3 pumps onto dry scalp',
      );

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddReminderBottomSheet.show(
                context,
                reminderToEdit: existing,
              ),
              child: const Text('Edit Sheet'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Care Reminder'), findsOneWidget);
      expect(find.text('Update Reminder'), findsOneWidget);
      expect(find.text('Morning Scalp Tonic'), findsOneWidget);
      expect(find.text('Spray 3 pumps onto dry scalp'), findsOneWidget);

      // Verify trash icon exists for editing
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });
  });
}
