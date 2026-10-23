import 'package:dr_hair/features/care/domain/models/care_models.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_state.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_state.dart';
import 'package:dr_hair/features/home/presentation/viewmodels/home_journey_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeJourneySelector', () {
    test('offers the assessment when it has not started', () {
      final action = HomeJourneySelector.select(
        hairState: const HairTestState(),
        careState: const CareState(),
      );

      expect(action.destination, HomeJourneyDestination.assessment);
      expect(action.buttonLabel, 'Start assessment');
    });

    test('offers to continue an assessment already in progress', () {
      final action = HomeJourneySelector.select(
        hairState: const HairTestState(currentStep: 2),
        careState: const CareState(),
      );

      expect(action.destination, HomeJourneyDestination.assessment);
      expect(action.buttonLabel, 'Continue assessment');
    });

    test('continues an available routine after assessment completion', () {
      final action = HomeJourneySelector.select(
        hairState: const HairTestState(isCompleted: true),
        careState: const CareState(
          routineTasks: [
            RoutineTask(
              id: 'local-task',
              title: 'Care step',
              subtitle: '',
              category: 'Care',
              timeOfDay: 'Evening',
            ),
          ],
        ),
      );

      expect(action.destination, HomeJourneyDestination.routine);
    });

    test('shows the assessment summary when no routine is available', () {
      final action = HomeJourneySelector.select(
        hairState: const HairTestState(isCompleted: true),
        careState: const CareState(),
      );

      expect(action.destination, HomeJourneyDestination.assessment);
      expect(action.buttonLabel, 'View assessment');
    });
  });
}
