import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'hair_test_state.dart';

class HairTestCubit extends Cubit<HairTestState> {
  final ImagePicker _imagePicker;

  HairTestCubit({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker(),
      super(const HairTestState());

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
      emit(state.copyWith(isSubmitted: true, clearErrorMessage: true));
    }
  }

  String? _validationMessageForCurrentStep() {
    switch (state.currentStep) {
      case 0:
        return state.selectedGender == null
            ? 'Choose an option to continue.'
            : null;
      case 1:
        return state.primaryConcern == null
            ? 'Choose your primary concern to continue.'
            : null;
      case 2:
        return state.duration == null
            ? 'Choose how long you have noticed hair fall.'
            : null;
      case 3:
        return state.stressLevel == null
            ? 'Choose a stress level to continue.'
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

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender, clearErrorMessage: true));
  }

  void selectPrimaryConcern(String concern) {
    emit(state.copyWith(primaryConcern: concern, clearErrorMessage: true));
  }

  void selectDuration(String duration) {
    emit(state.copyWith(duration: duration, clearErrorMessage: true));
  }

  void selectStressLevel(String level) {
    emit(state.copyWith(stressLevel: level, clearErrorMessage: true));
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
