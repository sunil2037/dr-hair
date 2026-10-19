import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'hair_test_state.dart';

class HairTestCubit extends Cubit<HairTestState> {
  final ImagePicker _imagePicker;

  HairTestCubit({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker(),
        super(const HairTestState());

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    } else {
      emit(state.copyWith(isSubmitted: true));
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender));
  }

  void selectPrimaryConcern(String concern) {
    emit(state.copyWith(primaryConcern: concern));
  }

  void selectDuration(String duration) {
    emit(state.copyWith(duration: duration));
  }

  void selectStressLevel(String level) {
    emit(state.copyWith(stressLevel: level));
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
        emit(
          state.copyWith(
            photos: updatedPhotos,
            isPickingImage: false,
          ),
        );
      } else {
        emit(state.copyWith(isPickingImage: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isPickingImage: false,
          errorMessage: 'Failed to pick image: $e',
        ),
      );
    }
  }

  void removePhoto(String label) {
    final updatedPhotos = Map<String, String>.from(state.photos);
    updatedPhotos.remove(label);
    emit(state.copyWith(photos: updatedPhotos));
  }

  void reset() {
    emit(const HairTestState());
  }
}
