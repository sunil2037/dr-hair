import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/hair_test/domain/models/hair_photo_analysis.dart';
import 'package:dr_hair/features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'package:dr_hair/features/treatment/data/patient_clinical_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(cubit.state.totalSteps, 8);
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

      cubit.selectPrimaryConcern('Crown Thinning');
      cubit.nextStep();
      expect(cubit.state.currentStep, 1);

      cubit.prevStep();
      expect(cubit.state.currentStep, 0);

      // Does not go below 0
      cubit.prevStep();
      expect(cubit.state.currentStep, 0);

      // Each question must be answered before advancing.
      cubit.nextStep(); // advances to 1 since concern was selected
      expect(cubit.state.currentStep, 1);
      cubit.selectDuration('1 - 3 years');
      cubit.nextStep(); // 2
      cubit.selectDandruff('Occasional flakes or itching');
      cubit.nextStep(); // 3
      cubit.selectStressLevel('Moderate');
      cubit.nextStep(); // 4
      cubit.selectGutHealth('Normal');
      cubit.nextStep(); // 5
      cubit.selectFamilyHistory("Mother's side");
      cubit.nextStep(); // 6
      cubit.setAllergyStatus('No known allergies');
      cubit.setCurrentMedicationsStatus('No');
      cubit.nextStep(); // 7
      expect(cubit.state.currentStep, 7);
      expect(cubit.state.isSubmitted, false);

      for (final label in [
        'Front Hairline',
        'Crown / Top',
        'Side Profile / Temples',
      ]) {
        await cubit.pickPhoto(label: label, source: ImageSource.gallery);
      }
      await cubit.nextStep();
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
      expect(cubit.state.getAnalysis('Front Hairline'), isNull);

      cubit.close();
    });

    test('pickPhoto analyzes photo and detects hair vs non-hair images', () async {
      // 1. Genuine hair photo
      final hairPicker = _FakeImagePicker(
        fileToReturn: XFile('/tmp/scalp_crown.jpg'),
      );
      final hairCubit = HairTestCubit(imagePicker: hairPicker);

      await hairCubit.pickPhoto(
        label: 'Crown / Top',
        source: ImageSource.camera,
      );

      final analysis = hairCubit.state.getAnalysis('Crown / Top');
      expect(analysis, isNotNull);
      expect(analysis!.isHair, isTrue);
      expect(analysis.status, HairDetectionStatus.hairDetected);
      expect(analysis.message, contains('Hair & scalp detected'));
      expect(hairCubit.state.hasNonHairPhoto, isFalse);
      hairCubit.close();

      // 2. Non-hair photo (e.g. document, car, random object)
      final nonHairPicker = _FakeImagePicker(
        fileToReturn: XFile('/tmp/car_non_hair.jpg'),
      );
      final nonHairCubit = HairTestCubit(imagePicker: nonHairPicker);

      await nonHairCubit.pickPhoto(
        label: 'Front Hairline',
        source: ImageSource.gallery,
      );

      final nonHairAnalysis = nonHairCubit.state.getAnalysis('Front Hairline');
      expect(nonHairAnalysis, isNotNull);
      expect(nonHairAnalysis!.isNotHair, isTrue);
      expect(nonHairAnalysis.status, HairDetectionStatus.notHair);
      expect(nonHairAnalysis.message, contains('No hair or scalp detected'));
      expect(nonHairCubit.state.hasNonHairPhoto, isTrue);
      nonHairCubit.close();
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

    test('bindPatient with server assessment restores submitted state and reference number', () async {
      SharedPreferences.setMockInitialValues({});
      await AppLocalCache.instance.clearAll();

      final fakeClinical = _FakeClinicalApi({
        'care_plans': [],
        'assessments': [
          {
            'id': 105,
            'reference_no': 'HT-2026-0099',
            'status': 'submitted',
            'full_name': 'Patient Sunil',
            'age': '28',
            'hair_loss_stage': 'Stage 2 - Receding hairline',
            'dandruff': 'Mild',
          },
        ],
        'reports': [],
        'appointments': [],
      });

      final cubit = HairTestCubit(clinicalApi: fakeClinical);
      await cubit.bindPatient('patient_sunil', sessionToken: 'mock_jwt_token');

      expect(cubit.state.isCompleted, isTrue);
      expect(cubit.state.isSubmitted, isTrue);
      expect(cubit.state.referenceNo, equals('HT-2026-0099'));
      expect(cubit.state.stage, equals('Stage 2 - Receding hairline'));
      expect(cubit.state.name, equals('Patient Sunil'));

      // Sign out / unbind clears state
      await cubit.bindPatient(null);
      expect(cubit.state.isCompleted, isFalse);
      expect(cubit.state.isSubmitted, isFalse);
      expect(cubit.state.referenceNo, isNull);

      cubit.close();
    });
  });
}

class _FakeClinicalApi extends PatientClinicalApi {
  final Map<String, dynamic> record;
  _FakeClinicalApi(this.record);

  @override
  Future<Map<String, dynamic>> getClinicalRecord(String accessToken) async {
    return record;
  }
}
