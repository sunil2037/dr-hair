import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';

void main() {
  group('CareCubit Tests', () {
    late CareCubit cubit;

    setUp(() {
      cubit = CareCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default clinical data populated', () {
      expect(cubit.state.checkIns.isNotEmpty, isTrue);
      expect(cubit.state.routineTasks.isNotEmpty, isTrue);
      expect(cubit.state.reminders.isNotEmpty, isTrue);
      expect(cubit.state.dietPlans.isNotEmpty, isTrue);
      expect(cubit.state.orders.isNotEmpty, isTrue);
      expect(cubit.state.routineStreakDays, equals(14));
    });

    test('addProgressCheckIn prepends new photo checkin to list', () {
      final initialCount = cubit.state.checkIns.length;
      cubit.addProgressCheckIn(
        date: DateTime.now(),
        imagePath: '/mock/path/scalp.jpg',
        scalpRegion: 'Crown / Vertex',
        sheddingLevel: 'Low / Normal',
        notes: 'Great hair density improvement',
        densityRating: 5,
      );

      expect(cubit.state.checkIns.length, equals(initialCount + 1));
      expect(
        cubit.state.checkIns.first.imagePath,
        equals('/mock/path/scalp.jpg'),
      );
      expect(cubit.state.checkIns.first.densityRating, equals(5));
    });

    test('deleteProgressCheckIn removes checkin by id', () {
      final firstId = cubit.state.checkIns.first.id;
      final initialCount = cubit.state.checkIns.length;

      cubit.deleteProgressCheckIn(firstId);
      expect(cubit.state.checkIns.length, equals(initialCount - 1));
      expect(cubit.state.checkIns.any((ci) => ci.id == firstId), isFalse);
    });

    test('toggleRoutineTask updates isCompleted status', () {
      final task = cubit.state.routineTasks.first;
      final wasCompleted = task.isCompleted;

      cubit.toggleRoutineTask(task.id);
      final updated = cubit.state.routineTasks.firstWhere(
        (t) => t.id == task.id,
      );
      expect(updated.isCompleted, equals(!wasCompleted));
    });

    test('addCustomRoutineTask adds custom task', () {
      final initialCount = cubit.state.routineTasks.length;
      cubit.addCustomRoutineTask(
        title: 'Scalp Dermarolling',
        subtitle: '0.5mm weekly needle roller',
        category: 'Clinical Topical',
        timeOfDay: 'Night',
      );

      expect(cubit.state.routineTasks.length, equals(initialCount + 1));
      expect(cubit.state.routineTasks.last.title, equals('Scalp Dermarolling'));
    });

    test('resetTodayRoutine marks all tasks incomplete', () {
      cubit.resetTodayRoutine();
      expect(cubit.state.routineTasks.every((t) => !t.isCompleted), isTrue);
      expect(cubit.state.completedRoutineCount, equals(0));
    });

    test('toggleReminder and updateReminderTime update reminder state', () {
      final reminder = cubit.state.reminders.first;
      final wasEnabled = reminder.isEnabled;

      cubit.toggleReminder(reminder.id, !wasEnabled);
      expect(
        cubit.state.reminders.firstWhere((r) => r.id == reminder.id).isEnabled,
        equals(!wasEnabled),
      );

      const newTime = TimeOfDay(hour: 7, minute: 45);
      cubit.updateReminderTime(reminder.id, newTime);
      expect(
        cubit.state.reminders.firstWhere((r) => r.id == reminder.id).time,
        equals(newTime),
      );
    });

    test(
      'toggleDietMeal and water intake functions update state correctly',
      () {
        cubit.selectDietDay(1);
        expect(cubit.state.currentDietDay, equals(1));

        final wasMealDone = cubit.state.dietPlans[1][0].isCompleted;
        cubit.toggleDietMeal(1, 0);
        expect(cubit.state.dietPlans[1][0].isCompleted, equals(!wasMealDone));

        final initialWater = cubit.state.waterCups;
        cubit.incrementWater();
        expect(cubit.state.waterCups, equals(initialWater + 1));

        cubit.decrementWater();
        expect(cubit.state.waterCups, equals(initialWater));
      },
    );
  });
}
