import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends Fake implements ImagePicker {
  final XFile? fileToReturn;

  _FakeImagePicker({this.fileToReturn});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return fileToReturn;
  }
}

void main() {
  group('HairTestCubit', () {
    test('initial state requires the user to provide answers', () {
      final cubit = HairTestCubit();
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.totalSteps, 5);
      expect(cubit.state.selectedGender, isNull);
      expect(cubit.state.primaryConcern, isNull);
      expect(cubit.state.duration, isNull);
      expect(cubit.state.stressLevel, isNull);
      expect(cubit.state.photos, isEmpty);
      expect(cubit.state.isSubmitted, false);
      cubit.close();
    });

    test('step progression validates answers and required photos', () async {
      final cubit = HairTestCubit(
        imagePicker: _FakeImagePicker(fileToReturn: XFile('/tmp/scalp.jpg')),
      );

      cubit.nextStep();
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.errorMessage, isNotNull);

      cubit.selectGender('Male');
      cubit.nextStep();
      expect(cubit.state.currentStep, 1);

      cubit.prevStep();
      expect(cubit.state.currentStep, 0);

      // Does not go below 0
      cubit.prevStep();
      expect(cubit.state.currentStep, 0);

      // Each question must be answered before advancing.
      cubit.nextStep(); // blocked at 0
      cubit.selectGender('Male');
      cubit.nextStep(); // 1
      cubit.selectPrimaryConcern('Crown Thinning');
      cubit.nextStep(); // 2
      cubit.selectDuration('1 - 3 years');
      cubit.nextStep(); // 3
      cubit.selectStressLevel('Moderate');
      cubit.nextStep(); // 4
      expect(cubit.state.currentStep, 4);
      expect(cubit.state.isSubmitted, false);

      cubit.nextStep(); // blocked until all required photos are added
      expect(cubit.state.isSubmitted, false);
      for (final label in [
        'Front Hairline',
        'Crown / Top',
        'Side Profile / Temples',
      ]) {
        await cubit.pickPhoto(label: label, source: ImageSource.gallery);
      }
      cubit.nextStep();
      expect(cubit.state.isSubmitted, true);

      cubit.close();
    });

    test('updates assessment answers', () {
      final cubit = HairTestCubit();

      cubit.selectGender('Female');
      expect(cubit.state.selectedGender, 'Female');

      cubit.selectPrimaryConcern('Receding Hairline (Temples)');
      expect(cubit.state.primaryConcern, 'Receding Hairline (Temples)');

      cubit.selectDuration('Less than 6 months');
      expect(cubit.state.duration, 'Less than 6 months');

      cubit.selectStressLevel('High Stress');
      expect(cubit.state.stressLevel, 'High Stress');

      cubit.close();
    });

    test('pickPhoto adds photo path to state for specified label', () async {
      final fakePicker = _FakeImagePicker(
        fileToReturn: XFile('/tmp/front.jpg'),
      );
      final cubit = HairTestCubit(imagePicker: fakePicker);

      await cubit.pickPhoto(
        label: 'Front Hairline',
        source: ImageSource.camera,
      );

      expect(cubit.state.hasPhoto('Front Hairline'), isTrue);
      expect(cubit.state.getPhoto('Front Hairline'), '/tmp/front.jpg');
      expect(cubit.state.isPickingImage, false);

      cubit.removePhoto('Front Hairline');
      expect(cubit.state.hasPhoto('Front Hairline'), isFalse);

      cubit.close();
    });

    test('reset clears state to initial defaults', () {
      final cubit = HairTestCubit();
      cubit.selectGender('Female');
      cubit.nextStep();

      cubit.reset();
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.selectedGender, isNull);
      expect(cubit.state.isSubmitted, false);

      cubit.close();
    });
  });
}
