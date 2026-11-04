import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/care/data/patient_progress_api.dart';
import 'package:dr_hair/features/care/data/patient_diet_api.dart';
import 'package:dr_hair/features/care/domain/models/care_models.dart';
import 'package:dr_hair/features/care/presentation/viewmodels/care_cubit.dart';
import 'package:dr_hair/features/treatment/data/patient_clinical_api.dart';

void main() {
  group('CareCubit Tests', () {
    late CareCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppLocalCache.instance.clearAll();
      cubit = CareCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state starts with clean unpopulated patient checkIns and orders', () {
      expect(cubit.state.checkIns, isEmpty);
      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.routineTasks, isEmpty);
      expect(cubit.state.reminders, isEmpty);
      expect(cubit.state.dietPlans, isEmpty);
    });

    test('addProgressCheckIn prepends new photo checkin to list', () {
      cubit.addProgressCheckIn(
        date: DateTime.now(),
        imagePath: '/mock/path/scalp.jpg',
        scalpRegion: 'Crown / Vertex',
        sheddingLevel: 'Low / Normal',
        notes: 'Great hair density improvement',
        densityRating: 5,
      );

      expect(cubit.state.checkIns.length, equals(1));
      expect(
        cubit.state.checkIns.first.imagePath,
        equals('/mock/path/scalp.jpg'),
      );
      expect(cubit.state.checkIns.first.densityRating, equals(5));
    });

    test('deleteProgressCheckIn removes checkin by id', () {
      cubit.addProgressCheckIn(
        date: DateTime.now(),
        imagePath: '/mock/path/scalp.jpg',
        scalpRegion: 'Crown / Vertex',
        sheddingLevel: 'Low / Normal',
        notes: 'Baseline photo',
      );
      final firstId = cubit.state.checkIns.first.id;

      cubit.deleteProgressCheckIn(firstId);
      expect(cubit.state.checkIns, isEmpty);
    });

    test('patient care data isolation: sign-out clears care data and cannot bleed between users', () async {
      await cubit.bindPatient('patient_101');
      cubit.addProgressCheckIn(
        date: DateTime.now(),
        imagePath: '/mock/path/patient1.jpg',
        scalpRegion: 'Frontal Hairline',
        sheddingLevel: 'Moderate',
        notes: 'Patient 101 private progress notes',
      );
      expect(cubit.state.checkIns.length, equals(1));
      expect(cubit.state.checkIns.first.notes, equals('Patient 101 private progress notes'));

      // Clear on sign out
      await cubit.clearPersonalCareData();
      expect(cubit.state.checkIns, isEmpty);

      // New patient signs in
      await cubit.bindPatient('patient_202');
      expect(cubit.state.checkIns, isEmpty);
    });

    test('toggleRoutineTask updates isCompleted status', () {
      cubit.loadSampleFixturesForTesting();
      final task = cubit.state.routineTasks.first;
      final wasCompleted = task.isCompleted;

      cubit.toggleRoutineTask(task.id);
      final updated = cubit.state.routineTasks.firstWhere(
        (t) => t.id == task.id,
      );
      expect(updated.isCompleted, equals(!wasCompleted));
    });

    test('addCustomRoutineTask adds custom task', () {
      final initialCount = cubit.state.routineTasks.length;
      cubit.addCustomRoutineTask(
        title: 'Scalp Dermarolling',
        subtitle: '0.5mm weekly needle roller',
        category: 'Clinical Topical',
        timeOfDay: 'Night',
      );

      expect(cubit.state.routineTasks.length, equals(initialCount + 1));
      expect(cubit.state.routineTasks.last.title, equals('Scalp Dermarolling'));
    });

    test('resetTodayRoutine marks all tasks incomplete', () {
      cubit.loadSampleFixturesForTesting();
      cubit.resetTodayRoutine();
      expect(cubit.state.routineTasks.every((t) => !t.isCompleted), isTrue);
      expect(cubit.state.completedRoutineCount, equals(0));
    });

    test('toggleReminder and updateReminderTime update reminder state', () {
      cubit.loadSampleFixturesForTesting();
      final reminder = cubit.state.reminders.first;
      final wasEnabled = reminder.isEnabled;

      cubit.toggleReminder(reminder.id, !wasEnabled);
      expect(
        cubit.state.reminders.firstWhere((r) => r.id == reminder.id).isEnabled,
        equals(!wasEnabled),
      );

      const newTime = TimeOfDay(hour: 7, minute: 45);
      cubit.updateReminderTime(reminder.id, newTime);
      expect(
        cubit.state.reminders.firstWhere((r) => r.id == reminder.id).time,
        equals(newTime),
      );
    });

    test(
      'toggleDietMeal and water intake functions update state correctly',
      () {
        cubit.loadSampleFixturesForTesting();
        cubit.selectDietDay(1);
        expect(cubit.state.currentDietDay, equals(1));

        final wasMealDone = cubit.state.dietPlans[1][0].isCompleted;
        cubit.toggleDietMeal(1, 0);
        expect(cubit.state.dietPlans[1][0].isCompleted, equals(!wasMealDone));

        final initialWater = cubit.state.waterCups;
        cubit.incrementWater();
        expect(cubit.state.waterCups, equals(initialWater + 1));

        cubit.decrementWater();
        expect(cubit.state.waterCups, equals(initialWater));
      },
    );

    test('bindPatient with sessionToken fetches clinician care plan and progress checkins', () async {
      final fakeClinical = _FakeClinicalApi({
        'care_plans': [
          {
            'reference_no': 'HT-2026-9001',
            'routine_steps': [
              {
                'title': 'Minoxidil 5% Application',
                'subtitle': 'Apply 1ml at night',
                'category': 'Clinical Topical',
                'time_of_day': 'Night',
              },
            ],
            'medications': [],
          },
        ],
        'assessments': [],
        'reports': [],
        'appointments': [],
      });

      final fakeProgress = _FakeProgressApi(
        checkIns: [
          {
            'id': 'ci_remote_1',
            'date': DateTime.now().toIso8601String(),
            'scalp_region': 'Crown',
            'shedding_level': 'Normal',
            'notes': 'Week 4 clinical checkin',
            'density_rating': 4,
            'photos': [
              {
                'angle': 'front',
                'url': 'https://res.cloudinary.com/demo/image/authenticated/s--signed--/user-101/front.jpg',
              },
            ],
          },
        ],
      );

      final backendBoundCubit = CareCubit(
        null,
        fakeClinical,
        fakeProgress,
      );

      await backendBoundCubit.bindPatient('patient_99', sessionToken: 'valid_jwt_token');

      expect(backendBoundCubit.state.routineTasks.length, equals(1));
      expect(backendBoundCubit.state.routineTasks.first.title, equals('Minoxidil 5% Application'));
      expect(backendBoundCubit.state.checkIns.length, equals(1));
      expect(backendBoundCubit.state.checkIns.first.id, equals('ci_remote_1'));
      expect(backendBoundCubit.state.checkIns.first.imagePath, contains('user-101/front.jpg'));

      // Deleting checkin delegates to progress api
      await backendBoundCubit.deleteProgressCheckIn('ci_remote_1', sessionToken: 'valid_jwt_token');
      expect(fakeProgress.deletedCheckInId, equals('ci_remote_1'));
      expect(backendBoundCubit.state.checkIns, isEmpty);

      // Unbinding patient clears state
      await backendBoundCubit.bindPatient(null);
      expect(backendBoundCubit.state.routineTasks, isEmpty);
      expect(backendBoundCubit.state.checkIns, isEmpty);

      backendBoundCubit.close();
    });

    test('fetchPatientDietPlan loads meals and treatment details from diet API', () async {
      final fakeDiet = _FakeDietApi(
        meals: [
          const DietMeal(
            type: 'Breakfast',
            name: 'Sprouted Moong & Paneer',
            nutrients: 'Protein (22g) · Biotin',
            benefit: 'Supports keratin production',
            isCompleted: false,
          ),
        ],
        treatmentName: 'Targeted Follicular Regrowth Diet',
        doctorName: 'Dr. Jai Bansal',
      );

      final dietCubit = CareCubit(null, null, null, null, fakeDiet);
      await dietCubit.fetchPatientDietPlan('test_jwt_token');

      expect(dietCubit.state.dietPlans.length, equals(1));
      expect(dietCubit.state.dietPlans.first.first.name, equals('Sprouted Moong & Paneer'));
      expect(dietCubit.state.dietTreatmentName, equals('Targeted Follicular Regrowth Diet'));
      expect(dietCubit.state.dietDoctorName, equals('Dr. Jai Bansal'));
      expect(dietCubit.state.isLoadingDiet, isFalse);

      dietCubit.close();
    });
  });
}

class _FakeDietApi extends PatientDietApi {
  final List<DietMeal> meals;
  final String treatmentName;
  final String doctorName;

  _FakeDietApi({
    this.meals = const [],
    this.treatmentName = 'Personalized Nutrition Plan',
    this.doctorName = 'Dr. Hair Clinical Team',
  });

  @override
  Future<PatientDietPlanResponse> getPatientDietPlan(String token) async {
    return PatientDietPlanResponse(
      meals: meals,
      treatmentName: treatmentName,
      doctorName: doctorName,
    );
  }
}

class _FakeClinicalApi extends PatientClinicalApi {
  final Map<String, dynamic> record;
  _FakeClinicalApi(this.record);

  @override
  Future<Map<String, dynamic>> getClinicalRecord(String accessToken) async {
    return record;
  }
}

class _FakeProgressApi extends PatientProgressApi {
  final List<Map<String, dynamic>> checkIns;
  String? deletedCheckInId;
  _FakeProgressApi({this.checkIns = const []});

  @override
  Future<List<Map<String, dynamic>>> listCheckIns({required String token}) async {
    return checkIns;
  }

  @override
  Future<void> deleteCheckIn({required String token, required String checkInId}) async {
    deletedCheckInId = checkInId;
  }
}
