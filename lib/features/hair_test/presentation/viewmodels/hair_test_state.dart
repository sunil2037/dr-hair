class HairTestState {
  final int currentStep;
  final int totalSteps;
  final String? selectedGender;
  final String? primaryConcern;
  final String? duration;
  final String? stressLevel;
  final Map<String, String> photos;
  final bool isSubmitted;
  final bool isPickingImage;
  final String? errorMessage;

  const HairTestState({
    this.currentStep = 0,
    this.totalSteps = 5,
    this.selectedGender = 'Male',
    this.primaryConcern = 'Crown Thinning',
    this.duration = '1 - 3 years',
    this.stressLevel = 'Moderate',
    this.photos = const {},
    this.isSubmitted = false,
    this.isPickingImage = false,
    this.errorMessage,
  });

  HairTestState copyWith({
    int? currentStep,
    int? totalSteps,
    String? selectedGender,
    String? primaryConcern,
    String? duration,
    String? stressLevel,
    Map<String, String>? photos,
    bool? isSubmitted,
    bool? isPickingImage,
    String? errorMessage,
  }) {
    return HairTestState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      selectedGender: selectedGender ?? this.selectedGender,
      primaryConcern: primaryConcern ?? this.primaryConcern,
      duration: duration ?? this.duration,
      stressLevel: stressLevel ?? this.stressLevel,
      photos: photos ?? this.photos,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      errorMessage: errorMessage,
    );
  }

  String? getPhoto(String label) => photos[label];
  bool hasPhoto(String label) =>
      photos.containsKey(label) &&
      photos[label] != null &&
      photos[label]!.isNotEmpty;
}
