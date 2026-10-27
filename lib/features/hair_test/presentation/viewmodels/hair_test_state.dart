/// Holds the user's assessment answers and completion status.
class HairTestState {
  final int currentStep;
  final int totalSteps;
  final String name;
  final String age;
  final String? selectedGender;
  final String? stage;
  final String? primaryConcern;
  final String? duration;
  final String? dandruff;
  final String? gutHealth;
  final String? stressLevel;
  final String? familyHistory;
  final Map<String, String> photos;
  final bool isSubmitted;
  final bool isCompleted;
  final bool isRetesting;
  final bool isPickingImage;
  final String? errorMessage;

  const HairTestState({
    this.currentStep = 0,
    this.totalSteps = 8,
    this.name = 'Sahil',
    this.age = '23',
    this.selectedGender,
    this.stage,
    this.primaryConcern,
    this.duration,
    this.dandruff,
    this.gutHealth,
    this.stressLevel,
    this.familyHistory,
    this.photos = const {},
    this.isSubmitted = false,
    this.isCompleted = false,
    this.isRetesting = false,
    this.isPickingImage = false,
    this.errorMessage,
  });

  HairTestState copyWith({
    int? currentStep,
    int? totalSteps,
    String? name,
    String? age,
    String? selectedGender,
    String? stage,
    bool clearStage = false,
    String? primaryConcern,
    String? duration,
    String? dandruff,
    String? gutHealth,
    String? stressLevel,
    String? familyHistory,
    Map<String, String>? photos,
    bool? isSubmitted,
    bool? isCompleted,
    bool? isRetesting,
    bool? isPickingImage,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HairTestState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      name: name ?? this.name,
      age: age ?? this.age,
      selectedGender: selectedGender ?? this.selectedGender,
      stage: clearStage ? null : stage ?? this.stage,
      primaryConcern: primaryConcern ?? this.primaryConcern,
      duration: duration ?? this.duration,
      dandruff: dandruff ?? this.dandruff,
      gutHealth: gutHealth ?? this.gutHealth,
      stressLevel: stressLevel ?? this.stressLevel,
      familyHistory: familyHistory ?? this.familyHistory,
      photos: photos ?? this.photos,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isCompleted: isCompleted ?? this.isCompleted,
      isRetesting: isRetesting ?? this.isRetesting,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  String? getPhoto(String label) => photos[label];
  bool hasPhoto(String label) =>
      photos.containsKey(label) && photos[label] != null && photos[label]!.isNotEmpty;

  /// Plain-language summary based on the answers selected by the user.
  String get assessmentSummary {
    final concern = primaryConcern?.trim();
    return stage ??
        (concern == null || concern.isEmpty ? 'Hair concern summary' : concern);
  }

  /// Cautious explanation of the selected stage, not a medical diagnosis.
  String get stageDescription {
    if (stage != null && stage!.contains('Stage 2')) {
      return 'Your answers suggest a Stage 2 hair-thinning pattern, such as a receding hairline or early crown thinning. This screening summary cannot confirm the cause; a qualified clinician can assess it with you.';
    }
    if (stage != null && stage!.contains('Stage 3')) {
      return 'Your answers suggest a more noticeable hair-thinning pattern. This screening summary cannot confirm the cause; a qualified clinician can assess it with you.';
    }
    if (stage != null && stage!.contains('Stage 1')) {
      return 'Your answers suggest an early hair-thinning pattern. This screening summary cannot confirm the cause; a qualified clinician can assess it with you.';
    }
    final concern = primaryConcern?.trim();
    if (concern != null && concern.isNotEmpty) {
      return 'You shared $concern as your main concern. This summary is a starting point, not a diagnosis; a qualified clinician can assess it with you.';
    }
    return 'Your answers provide a starting point for discussing your hair concerns with a qualified clinician.';
  }
}
