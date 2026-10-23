/// Represents the assessment state inspired by Traya clinical root cause analysis,
/// diagnostics, stage classification, and persistent completion status.
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
    this.totalSteps = 5,
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
      stage: stage ?? this.stage,
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

  /// Traya-style Diagnosed Condition & Stage
  String get diagnosedTitle {
    if (stage != null && stage!.contains('Stage 2')) {
      return 'Stage-2, Progressive Hair Fall';
    } else if (stage != null && stage!.contains('Stage 3')) {
      return 'Stage-3, Advanced Follicular Thinning';
    }
    return 'Stage-1, Male Pattern Hair Fall';
  }

  /// Estimated Timeline for Visual Regrowth
  String get resultsTimeline {
    if (stage != null && stage!.contains('Stage 3')) {
      return '7 - 8 months';
    } else if (stage != null && stage!.contains('Stage 2')) {
      return '6 months';
    }
    return '5 months';
  }

  /// Description of the diagnosed stage
  String get stageDescription {
    if (stage != null && stage!.contains('Stage 2')) {
      return 'Stage 2 hair fall involves noticeable receding at the hairline and early thinning on the crown.\n\nFollicles are actively miniaturizing from DHT and scalp inflammation, but can be revitalized with a consistent 3-month medical regimen.';
    }
    return 'Stage 1 male pattern hair fall is marked by minor hair thinning at the crown or front of your head.\n\nHair follicle damage is very mild at this stage and can be easily stopped from progressing further if the regimen is started early.';
  }
}
