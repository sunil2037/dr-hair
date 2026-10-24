import '../../../care/presentation/viewmodels/care_state.dart';
import '../../../hair_test/presentation/viewmodels/hair_test_state.dart';

enum HomeJourneyDestination { assessment, routine, progress }

class HomeJourneyAction {
  final String title;
  final String description;
  final String buttonLabel;
  final HomeJourneyDestination destination;

  const HomeJourneyAction({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.destination,
  });
}

/// Chooses one Home action from the local assessment and care state.
class HomeJourneySelector {
  const HomeJourneySelector._();

  static bool hasAssessmentProgress(HairTestState state) =>
      state.isRetesting ||
      state.currentStep > 0 ||
      state.selectedGender != null ||
      state.stage != null ||
      state.primaryConcern != null ||
      state.dandruff != null ||
      state.duration != null ||
      state.gutHealth != null ||
      state.stressLevel != null ||
      state.photos.isNotEmpty;

  static HomeJourneyAction select({
    required HairTestState hairState,
    required CareState careState,
  }) {
    if (!hairState.isCompleted || hairState.isRetesting) {
      final inProgress = hasAssessmentProgress(hairState);
      return HomeJourneyAction(
        title: inProgress
            ? 'Continue your assessment'
            : 'Start with a hair assessment',
        description: inProgress
            ? 'Continue your assessment from the current step.'
            : 'Answer a few questions to create an informational starting point for your care journey.',
        buttonLabel: inProgress ? 'Continue assessment' : 'Start assessment',
        destination: HomeJourneyDestination.assessment,
      );
    }

    if (careState.routineTasks.any((task) => !task.isCompleted)) {
      return const HomeJourneyAction(
        title: 'Continue your care routine',
        description:
            'Open your routine to review the care steps available today.',
        buttonLabel: 'Open routine',
        destination: HomeJourneyDestination.routine,
      );
    }

    if (careState.routineTasks.isEmpty) {
      return const HomeJourneyAction(
        title: 'Your restoration journey is ready',
        description: 'Start your daily care routine and track your progress over time.',
        buttonLabel: 'Start daily routine',
        destination: HomeJourneyDestination.routine,
      );
    }

    return const HomeJourneyAction(
      title: 'Check in on your progress',
      description:
          'Review your progress notes or add a new check-in when you’re ready.',
      buttonLabel: 'View progress',
      destination: HomeJourneyDestination.progress,
    );
  }
}
