import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/storage/app_local_cache.dart';
import 'hair_test_state.dart';

class HairTestCubit extends Cubit<HairTestState> {
  final ImagePicker _imagePicker;
  final AppLocalCache _cache;

  HairTestCubit({ImagePicker? imagePicker, AppLocalCache? cache})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _cache = cache ?? AppLocalCache.instance,
      super(const HairTestState());

  Future<void> loadSavedState() async {
    try {
      final hasCompleted = _cache.getBool('has_completed_hair_test') ?? false;
      final savedStage = _cache.getString('hair_test_stage');
      final savedDandruff = _cache.getString('hair_test_dandruff');
      final savedName = _cache.getString('hair_test_name') ?? 'Sahil';
      final savedAge = _cache.getString('hair_test_age') ?? '23';

      if (hasCompleted) {
        emit(
          state.copyWith(
            isCompleted: true,
            name: savedName,
            age: savedAge,
            stage: savedStage ?? 'Stage 1 - Mild temple thinning',
            dandruff: savedDandruff ?? 'Severe Dandruff & Flakes',
          ),
        );
      }
    } catch (_) {}
  }

  void nextStep() {
    final validationMessage = _validationMessageForCurrentStep();
    if (validationMessage != null) {
      emit(state.copyWith(errorMessage: validationMessage));
      return;
    }

    if (state.currentStep < state.totalSteps - 1) {
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          clearErrorMessage: true,
        ),
      );
    } else {
      submitTest();
    }
  }

  String? _validationMessageForCurrentStep() {
    switch (state.currentStep) {
      case 0:
        return state.selectedGender == null
            ? 'Choose an option to continue.'
            : null;
      case 1:
        return state.stage == null && state.primaryConcern == null
            ? 'Choose your hair fall stage or primary concern to continue.'
            : null;
      case 2:
        return state.dandruff == null && state.duration == null
            ? 'Choose your scalp condition or hair fall duration to continue.'
            : null;
      case 3:
        return state.stressLevel == null && state.gutHealth == null
            ? 'Choose your lifestyle & stress pattern to continue.'
            : null;
      case 4:
        return [
              'Front Hairline',
              'Crown / Top',
              'Side Profile / Temples',
            ].every(state.hasPhoto)
            ? null
            : 'Add all three scalp photos before submitting.';
      default:
        return null;
    }
  }

  Future<void> skipPhotosAndSubmit() async {
    await submitTest();
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> submitTest() async {
    emit(
      state.copyWith(
        isSubmitted: true,
        isCompleted: true,
        isRetesting: false,
        clearErrorMessage: true,
      ),
    );

    try {
      await _cache.put('has_completed_hair_test', true);
      if (state.stage != null) {
        await _cache.put('hair_test_stage', state.stage!);
      }
      if (state.dandruff != null) {
        await _cache.put('hair_test_dandruff', state.dandruff!);
      }
      await _cache.put('hair_test_name', state.name);
      await _cache.put('hair_test_age', state.age);
    } catch (_) {}
  }

  void startRetest() {
    emit(
      state.copyWith(
        isRetesting: true,
        isSubmitted: false,
        currentStep: 0,
        clearErrorMessage: true,
      ),
    );
  }

  void dismissReport() {
    emit(
      state.copyWith(
        isSubmitted: false,
        isRetesting: false,
        currentStep: 0,
        clearErrorMessage: true,
      ),
    );
  }

  void setPatientInfo({String? name, String? age}) {
    emit(
      state.copyWith(
        name: name ?? state.name,
        age: age ?? state.age,
        clearErrorMessage: true,
      ),
    );
  }

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender, clearErrorMessage: true));
  }

  void selectStage(String stage) {
    emit(
      state.copyWith(
        stage: stage,
        primaryConcern: stage,
        clearErrorMessage: true,
      ),
    );
  }

  void selectPrimaryConcern(String concern) {
    emit(
      state.copyWith(
        primaryConcern: concern,
        stage: concern,
        clearErrorMessage: true,
      ),
    );
  }

  void selectDandruff(String condition) {
    emit(state.copyWith(dandruff: condition, clearErrorMessage: true));
  }

  void selectGutHealth(String gut) {
    emit(state.copyWith(gutHealth: gut, clearErrorMessage: true));
  }

  void selectStressLevel(String level) {
    emit(state.copyWith(stressLevel: level, clearErrorMessage: true));
  }

  void selectFamilyHistory(String history) {
    emit(state.copyWith(familyHistory: history, clearErrorMessage: true));
  }

  void selectDuration(String duration) {
    emit(state.copyWith(duration: duration, clearErrorMessage: true));
  }

  Future<void> pickPhoto({
    required String label,
    required ImageSource source,
  }) async {
    emit(state.copyWith(isPickingImage: true, errorMessage: null));
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        final updatedPhotos = Map<String, String>.from(state.photos);
        updatedPhotos[label] = pickedFile.path;
        emit(state.copyWith(photos: updatedPhotos, isPickingImage: false));
      } else {
        emit(state.copyWith(isPickingImage: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isPickingImage: false,
          errorMessage: 'Could not open the image picker. Please try again.',
        ),
      );
    }
  }

  void setPhoto(String label, String path) {
    final updatedPhotos = Map<String, String>.from(state.photos);
    updatedPhotos[label] = path;
    emit(state.copyWith(photos: updatedPhotos, clearErrorMessage: true));
  }

  void removePhoto(String label) {
    final updatedPhotos = Map<String, String>.from(state.photos);
    updatedPhotos.remove(label);
    emit(state.copyWith(photos: updatedPhotos, clearErrorMessage: true));
  }

  void reset() {
    emit(const HairTestState());
  }
}
