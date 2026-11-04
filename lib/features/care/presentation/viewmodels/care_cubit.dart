import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/care_notification_service.dart';
import '../../data/patient_progress_api.dart';
import '../../data/patient_diet_api.dart';
import '../../domain/models/care_models.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../../../treatment/data/patient_clinical_api.dart';
import '../../../shop/data/datasources/commerce_remote_data_source.dart';
import 'care_state.dart';

class CareCubit extends Cubit<CareState> {
  static const _routineHistoryKey = 'care_routine_completion_days_v1';
  static const _careDataClearedKey = 'care_personal_data_cleared_v1';
  final CareNotificationService? _notificationService;
  final PatientClinicalApi _clinicalApi;
  final PatientProgressApi _progressApi;
  final CommerceRemoteDataSource _commerceDataSource;
  final PatientDietApi _dietApi;
  String? _patientId;
  String? _sessionToken;

  String get _checkInsKey => _patientId != null && _patientId!.isNotEmpty
      ? 'care_checkins_${_patientId}_v1'
      : 'care_checkins_v1';

  String get _ordersKey => _patientId != null && _patientId!.isNotEmpty
      ? 'care_orders_${_patientId}_v1'
      : 'care_orders_v1';

  String get _routineTasksKey => _patientId != null && _patientId!.isNotEmpty
      ? 'care_routine_tasks_${_patientId}_v1'
      : 'care_routine_tasks_v1';

  CareCubit([
    this._notificationService,
    PatientClinicalApi? clinicalApi,
    PatientProgressApi? progressApi,
    CommerceRemoteDataSource? commerceDataSource,
    PatientDietApi? dietApi,
  ])  : _clinicalApi = clinicalApi ?? PatientClinicalApi(),
        _progressApi = progressApi ?? PatientProgressApi(),
        _commerceDataSource = commerceDataSource ?? CommerceRemoteDataSource(),
        _dietApi = dietApi ?? PatientDietApi(),
        super(const CareState()) {
    _initPersistence();
  }

  Future<void> bindPatient(String? patientId, {String? sessionToken}) async {
    if (patientId == null || patientId.isEmpty) {
      _patientId = null;
      _sessionToken = null;
      if (!isClosed) emit(const CareState());
      return;
    }
    _patientId = patientId;
    _sessionToken = sessionToken;
    await _initPersistence();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      await _syncWithBackend(sessionToken);
    }
  }

  void loadSampleFixturesForTesting() {
    if (isClosed) return;
    _initializeDefaultData();
    emit(
      state.copyWith(
        checkIns: ProgressCheckIn.sampleFixtures,
      ),
    );
  }

  Future<void> _initPersistence() async {
    final service =
        _notificationService ?? await CareNotificationService.create();
    final status = service.getPermissionStatus();
    final persistedReminders = service.loadReminders();
    final cache = AppLocalCache.instance;
    final cachedTasks = _readList(
      cache.getString(_routineTasksKey),
      RoutineTask.fromJson,
    );
    final persistedTasks = cachedTasks ?? service.loadRoutineTasks();
    final today = _localDayKey(DateTime.now());
    final storedRoutineDay = service.loadRoutineDay();
    final routineTasks = (persistedTasks ?? state.routineTasks)
        .map(
          (task) => storedRoutineDay == today
              ? task
              : task.copyWith(isCompleted: false),
        )
        .toList();
    await service.saveRoutineTasks(routineTasks);
    await service.saveRoutineDay(today);
    final checkIns = _readList(
      cache.getString(_checkInsKey),
      ProgressCheckIn.fromJson,
    );
    final orders = _readList(cache.getString(_ordersKey), CareOrder.fromJson);
    final routineDays = _readList<String>(
      cache.getString(_routineHistoryKey),
      (json) => json['day'] as String? ?? '',
    );

    if (isClosed) return;
    emit(
      state.copyWith(
        notificationPermissionStatus: status,
        reminders: persistedReminders ?? state.reminders,
        routineTasks: routineTasks,
        checkIns: checkIns ?? state.checkIns,
        orders: orders ?? state.orders,
        routineCompletionDays: routineDays ?? state.routineCompletionDays,
      ),
    );
  }

  Future<void> _syncWithBackend(String token) async {
    try {
      final record = await _clinicalApi.getClinicalRecord(token);
      final carePlans = record['care_plans'] as List? ?? [];
      List<RoutineTask>? serverTasks;
      if (carePlans.isNotEmpty) {
        final activePlan = carePlans.first;
        if (activePlan is Map) {
          final steps = activePlan['routine_steps'] as List? ?? [];
          final completionMap = {
            for (final t in state.routineTasks) t.title: t.isCompleted
          };
          serverTasks = steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            if (step is! Map) return null;
            final tTitle = step['title']?.toString() ?? '';
            return RoutineTask(
              id: 'rt_${idx + 1}',
              title: tTitle,
              subtitle: step['subtitle']?.toString() ?? '',
              category: step['category']?.toString() ?? 'Treatment',
              timeOfDay: step['time_of_day']?.toString() ?? 'Daily',
              isCompleted: completionMap[tTitle] ?? false,
            );
          }).whereType<RoutineTask>().where((t) => t.title.isNotEmpty).toList();
        }
      }

      // Also check direct routine-steps endpoint
      try {
        final directSteps = await _clinicalApi.getRoutineSteps(token);
        if (directSteps.isNotEmpty) {
          final completionMap = {
            for (final t in state.routineTasks) t.title: t.isCompleted
          };
          serverTasks = directSteps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final tTitle = step['title']?.toString() ?? '';
            return RoutineTask(
              id: 'rt_${idx + 1}',
              title: tTitle,
              subtitle: step['subtitle']?.toString() ?? '',
              category: step['category']?.toString() ?? 'Lifestyle',
              timeOfDay: step['time_of_day']?.toString() ?? 'Daily',
              isCompleted: completionMap[tTitle] ?? false,
            );
          }).where((t) => t.title.isNotEmpty).toList();
        }
      } catch (_) {}

      List<ProgressCheckIn>? serverCheckIns;
      try {
        final rawCheckIns = await _progressApi.listCheckIns(token: token);
        serverCheckIns = rawCheckIns.map((item) {
          final photos = (item['photos'] as List? ?? []);
          String? front;
          String? top;
          String? back;
          for (final p in photos) {
            if (p is Map) {
              final angle = p['angle']?.toString().toLowerCase();
              final url = p['url']?.toString();
              if (angle == 'front') front = url;
              if (angle == 'top') top = url;
              if (angle == 'back') back = url;
            }
          }
          final primaryPhoto = front ?? top ?? back ?? '';
          final dateStr = item['date']?.toString();
          final date = dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();
          return ProgressCheckIn(
            id: item['id']?.toString() ?? '',
            date: date,
            imagePath: primaryPhoto,
            frontImagePath: front,
            topImagePath: top,
            backImagePath: back,
            scalpRegion: item['scalp_region']?.toString() ?? 'Scalp',
            sheddingLevel: item['shedding_level']?.toString() ?? 'Normal',
            notes: item['notes']?.toString() ?? '',
            densityRating: (item['density_rating'] as num?)?.toInt() ?? 3,
            isDoctorReviewed: item['doctor_note'] != null &&
                item['doctor_note'].toString().trim().isNotEmpty,
            doctorNote: item['doctor_note']?.toString(),
          );
        }).where((ci) => ci.id.isNotEmpty).toList();
      } catch (_) {}

      List<CareOrder>? serverOrders;
      try {
        final rawOrders = await _commerceDataSource.fetchPatientOrders(token: token);
        if (rawOrders.isNotEmpty) {
          serverOrders = rawOrders;
        }
      } catch (_) {}

      if (isClosed) return;
      emit(
        state.copyWith(
          routineTasks: serverTasks ??
              (carePlans.isEmpty ? const [] : state.routineTasks),
          checkIns: serverCheckIns ?? state.checkIns,
          orders: serverOrders ?? state.orders,
        ),
      );
      _persistCheckIns();
      if (serverOrders != null) {
        _persistOrders();
      }
      if (serverTasks != null) {
        _persistRoutineTasks();
      }
      await fetchPatientDietPlan(token);
    } catch (_) {}
  }

  Future<void> fetchPatientDietPlan([String? token]) async {
    final activeToken = token ?? _sessionToken;
    if (activeToken == null || activeToken.isEmpty) return;

    if (!isClosed) {
      emit(state.copyWith(isLoadingDiet: true));
    }

    try {
      final res = await _dietApi.getPatientDietPlan(activeToken);
      if (!isClosed) {
        final List<List<DietMeal>> plans = res.meals.isNotEmpty
            ? [res.meals]
            : state.dietPlans;
        emit(
          state.copyWith(
            dietPlans: plans,
            dietTreatmentName: res.treatmentName,
            dietDoctorName: res.doctorName,
            isLoadingDiet: false,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingDiet: false));
      }
    }
  }

  void _initializeDefaultData() {
    if (AppLocalCache.instance.getBool(_careDataClearedKey) == true) return;
    const defaultCheckIns = <ProgressCheckIn>[];

    final defaultTasks = [
      const RoutineTask(
        id: 'rt_1',
        title: 'Dr.Hair 5% Topical Regrowth Booster',
        subtitle: 'Apply 1ml with dropper evenly on crown and hairline',
        category: 'Clinical Topical',
        timeOfDay: 'Evening',
        isCompleted: false,
      ),
      const RoutineTask(
        id: 'rt_2',
        title: 'Biotin & Saw Palmetto Complex',
        subtitle: '1 tablet post-breakfast with water',
        category: 'Oral Supplement',
        timeOfDay: 'Morning',
        isCompleted: false,
      ),
      const RoutineTask(
        id: 'rt_3',
        title: 'Scalp Micro-Circulation Massage',
        subtitle: '4-5 minutes gentle circular fingertips massage',
        category: 'Lifestyle',
        timeOfDay: 'Night',
        isCompleted: false,
      ),
      const RoutineTask(
        id: 'rt_4',
        title: 'Hydration Goal (2.5L Water)',
        subtitle: 'Essential for cellular follicular transport',
        category: 'Lifestyle',
        timeOfDay: 'Throughout Day',
        isCompleted: false,
      ),
    ];

    final defaultReminders = [
      const CareReminder(
        id: 'rem_1',
        title: 'Morning Supplement',
        subtitle: 'Biotin & Saw Palmetto after breakfast',
        time: TimeOfDay(hour: 9, minute: 0),
        isEnabled: true,
        frequency: 'Daily',
      ),
      const CareReminder(
        id: 'rem_2',
        title: 'Evening Topical Booster',
        subtitle: 'Apply 1ml solution before bed',
        time: TimeOfDay(hour: 21, minute: 30),
        isEnabled: true,
        frequency: 'Daily',
      ),
      const CareReminder(
        id: 'rem_3',
        title: 'Weekly Scalp Wash & Exfoliation',
        subtitle: 'Use ketoconazole / clarifying cleanser',
        time: TimeOfDay(hour: 10, minute: 0),
        isEnabled: true,
        frequency: 'Weekly',
      ),
      const CareReminder(
        id: 'rem_4',
        title: 'Monthly Progress Photo Check-in',
        subtitle: 'Take photos under consistent lighting',
        time: TimeOfDay(hour: 11, minute: 0),
        isEnabled: false,
        frequency: 'Monthly',
      ),
    ];

    final defaultDiet = [
      // Day 1: High Protein & Keratin
      [
        const DietMeal(
          type: 'Breakfast',
          name: 'Sprouted Moong & Paneer Omelette / Scramble',
          nutrients: 'Protein (22g) · Biotin · Iron',
          benefit: 'Provides sulfur-rich amino acids required to produce keratin protein chains.',
          isCompleted: true,
        ),
        const DietMeal(
          type: 'Lunch',
          name: 'Palak Dal with Brown Rice & Raw Salad',
          nutrients: 'Folate · Zinc · Plant Iron',
          benefit: 'Enhances red blood cell hemoglobin for optimal oxygen supply to roots.',
          isCompleted: true,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Roasted Pumpkin & Sunflower Seeds with Walnuts',
          nutrients: 'Omega-3 · Zinc · Magnesium',
          benefit: 'Natural 5-alpha reductase enzyme inhibitor to counter follicular sensitivity.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Steamed Greens with Soya Chunks or Grilled Fish',
          nutrients: 'Keratin building blocks · Vitamin E',
          benefit: 'Supports nocturnal follicle matrix cellular regeneration.',
          isCompleted: false,
        ),
      ],
      // Day 2: Zinc & Folate Focus
      [
        const DietMeal(
          type: 'Breakfast',
          name: 'Oats Porridge with Chia Seeds, Almonds & Berries',
          nutrients: 'Silica · Zinc · Antioxidants',
          benefit:
              'Prevents oxidative stress around hair dermal papilla cells.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Lunch',
          name: 'Rajma / Chickpea Curry with Cucumber Raita',
          nutrients: 'Protein (18g) · B-Complex',
          benefit: 'Aids DNA replication and active anagen phase elongation.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Amla (Indian Gooseberry) Juice with Flax Crackers',
          nutrients: 'Vitamin C · Collagen Co-factor',
          benefit: 'Powers scalp collagen synthesis and increases non-heme iron absorption.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Mixed Vegetable Khichdi with Ghee & Curd',
          nutrients: 'Butyric acid · Probiotics',
          benefit: 'Healthy gut microbiome ensures complete micronutrient assimilation.',
          isCompleted: false,
        ),
      ],
      // Day 3: Iron & Follicular Circulation
      [
        const DietMeal(
          type: 'Breakfast',
          name: 'Boiled Eggs / Tofu Stir-Fry with Multigrain Toast',
          nutrients: 'Choline · Vitamin D3 · Protein',
          benefit:
              'Key catalyst for waking dormant telogen follicles into anagen.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Lunch',
          name: 'Methi (Fenugreek) Roti with Black Chana Curry',
          nutrients: 'Nicotinic Acid · Iron · Lecithin',
          benefit: 'Strengthens hair shafts and minimizes breakage.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Greek Yogurt with Crushed Brazil Nuts',
          nutrients: 'Selenium · Calcium',
          benefit: 'Supports thyroid hormone balance vital for healthy shedding cycle.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Paneer / Tofu Bhurji with Sauted Bell Peppers',
          nutrients: 'Vitamin A · Carotenoids',
          benefit: 'Normalizes sebum secretion across scalp for healthy follicle breathing.',
          isCompleted: false,
        ),
      ],
    ];

    const defaultOrders = <CareOrder>[];

    emit(
      CareState(
        checkIns: defaultCheckIns,
        routineTasks: defaultTasks,
        reminders: defaultReminders,
        dietPlans: defaultDiet,
        currentDietDay: 0,
        waterCups: 6,
        orders: defaultOrders,
      ),
    );
  }

  // --- PROGRESS CHECK-IN ACTIONS ---
  void addProgressCheckIn({
    String? id,
    required DateTime date,
    required String imagePath,
    String? frontImagePath,
    String? backImagePath,
    String? topImagePath,
    required String scalpRegion,
    required String sheddingLevel,
    required String notes,
    int densityRating = 4,
    String? doctorNote,
  }) {
    final newCheckIn = ProgressCheckIn(
      id: id ?? 'ci_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      imagePath: imagePath,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
      topImagePath: topImagePath,
      scalpRegion: scalpRegion,
      sheddingLevel: sheddingLevel,
      notes: notes,
      densityRating: densityRating,
      isDoctorReviewed: false,
      doctorNote:
          doctorNote ??
          'Saved on this device. No clinician has reviewed this check-in.',
    );

    emit(state.copyWith(checkIns: [newCheckIn, ...state.checkIns]));
    _persistCheckIns();
  }

  Future<void> deleteProgressCheckIn(String id, {String? sessionToken}) async {
    if (isClosed) return;
    final token = sessionToken ?? _sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _progressApi.deleteCheckIn(token: token, checkInId: id);
      } catch (_) {}
    }
    emit(
      state.copyWith(
        checkIns: state.checkIns.where((ci) => ci.id != id).toList(),
      ),
    );
    _persistCheckIns();
  }

  // --- ROUTINE ACTIONS ---
  void toggleRoutineTask(String id) {
    final updated = state.routineTasks.map((task) {
      if (task.id == id) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();

    emit(state.copyWith(routineTasks: updated));
    _persistRoutineTasks();
    _notificationService?.saveRoutineTasks(updated);
    _saveRoutineDay();
    _recordRoutineCompletionIfDone(updated);
  }

  Future<bool> addCustomRoutineTask({
    required String title,
    required String subtitle,
    required String category,
    required String timeOfDay,
  }) async {
    final newTask = RoutineTask(
      id: 'rt_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      category: category,
      timeOfDay: timeOfDay,
      isCompleted: false,
    );

    final updated = [...state.routineTasks, newTask];
    emit(state.copyWith(routineTasks: updated));
    _persistRoutineTasks();
    _notificationService?.saveRoutineTasks(updated);
    _saveRoutineDay();
    _recordRoutineCompletionIfDone(updated);

    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      try {
        final serverSteps = await _clinicalApi.addRoutineStep(
          accessToken: _sessionToken!,
          title: title,
          subtitle: subtitle,
          category: category,
          timeOfDay: timeOfDay,
        );
        if (serverSteps.isNotEmpty && !isClosed) {
          final completionMap = {
            for (final t in state.routineTasks) t.title: t.isCompleted
          };
          final refreshed = serverSteps.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final tTitle = s['title']?.toString() ?? '';
            return RoutineTask(
              id: 'rt_${idx + 1}',
              title: tTitle,
              subtitle: s['subtitle']?.toString() ?? '',
              category: s['category']?.toString() ?? 'Lifestyle',
              timeOfDay: s['time_of_day']?.toString() ?? 'Daily',
              isCompleted: completionMap[tTitle] ?? false,
            );
          }).where((t) => t.title.isNotEmpty).toList();

          emit(state.copyWith(routineTasks: refreshed));
          _persistRoutineTasks();
          _notificationService?.saveRoutineTasks(refreshed);
        }
      } catch (_) {
        // Optimistic local update is already saved
      }
    }
    return true;
  }

  Future<bool> removeRoutineTask(RoutineTask task) async {
    final index = state.routineTasks.indexOf(task);
    if (index < 0) return false;

    final updated = List<RoutineTask>.from(state.routineTasks)..removeAt(index);
    emit(state.copyWith(routineTasks: updated));
    _persistRoutineTasks();
    _notificationService?.saveRoutineTasks(updated);
    _saveRoutineDay();

    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      try {
        await _clinicalApi.deleteRoutineStep(
          accessToken: _sessionToken!,
          stepIndex: index,
        );
      } catch (_) {}
    }
    return true;
  }

  void resetTodayRoutine() {
    final reset = state.routineTasks
        .map((task) => task.copyWith(isCompleted: false))
        .toList();
    emit(state.copyWith(routineTasks: reset));
    _persistRoutineTasks();
    _notificationService?.saveRoutineTasks(reset);
    _saveRoutineDay();
    _recordRoutineCompletionIfDone(reset);
  }

  String _localDayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _saveRoutineDay() {
    _notificationService?.saveRoutineDay(_localDayKey(DateTime.now()));
  }

  void _recordRoutineCompletionIfDone(List<RoutineTask> tasks) {
    final day = _localDayKey(DateTime.now());
    final updatedDays = Set<String>.from(state.routineCompletionDays);
    if (tasks.isNotEmpty && tasks.every((task) => task.isCompleted)) {
      updatedDays.add(day);
    } else {
      updatedDays.remove(day);
    }
    final days = updatedDays.toList()..sort();
    emit(state.copyWith(routineCompletionDays: days));
    AppLocalCache.instance.put(
      _routineHistoryKey,
      jsonEncode(days.map((entry) => {'day': entry}).toList()),
    );
  }

  // --- REMINDER ACTIONS ---
  Future<void> requestNotificationPermission({
    bool simulateDenial = false,
  }) async {
    final service =
        _notificationService ?? await CareNotificationService.create();
    final status = await service.requestPermission(
      simulateDenial: simulateDenial,
    );
    emit(state.copyWith(notificationPermissionStatus: status));
  }

  void saveReminder(CareReminder reminder) {
    final existingIndex = state.reminders.indexWhere(
      (r) => r.id == reminder.id,
    );
    List<CareReminder> updated;
    if (existingIndex >= 0) {
      updated = List<CareReminder>.from(state.reminders);
      updated[existingIndex] = reminder;
    } else {
      updated = [...state.reminders, reminder];
    }
    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
    if (reminder.isEnabled) {
      _notificationService?.scheduleReminder(reminder);
    } else {
      _notificationService?.cancelReminder(reminder.id);
    }
  }

  void deleteReminder(String id) {
    final updated = state.reminders.where((r) => r.id != id).toList();
    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
    _notificationService?.cancelReminder(id);
  }

  void toggleReminder(String id, bool isEnabled) {
    final updated = state.reminders.map((rem) {
      if (rem.id == id) {
        final r = rem.copyWith(isEnabled: isEnabled);
        if (isEnabled) {
          _notificationService?.scheduleReminder(r);
        } else {
          _notificationService?.cancelReminder(r.id);
        }
        return r;
      }
      return rem;
    }).toList();

    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
  }

  void updateReminderTime(String id, TimeOfDay newTime) {
    final updated = state.reminders.map((rem) {
      if (rem.id == id) {
        final r = rem.copyWith(time: newTime);
        _notificationService?.scheduleReminder(r);
        return r;
      }
      return rem;
    }).toList();

    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
  }

  void snoozeReminder(
    String id, {
    Duration duration = const Duration(minutes: 15),
  }) {
    final until = DateTime.now().add(duration);
    final updated = state.reminders.map((rem) {
      if (rem.id == id) {
        return rem.copyWith(snoozedUntil: until);
      }
      return rem;
    }).toList();

    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
  }

  void toggleReminderCompletion(String id) {
    final updated = state.reminders.map((rem) {
      if (rem.id == id) {
        return rem.copyWith(isCompleted: !rem.isCompleted, clearSnooze: true);
      }
      return rem;
    }).toList();

    emit(state.copyWith(reminders: updated));
    _notificationService?.saveReminders(updated);
  }

  void addReminder({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required String frequency,
    String treatmentType = 'Topical Serum',
    List<int> repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    String notes = '',
  }) {
    final newReminder = CareReminder(
      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      time: time,
      frequency: frequency,
      treatmentType: treatmentType,
      repeatDays: repeatDays,
      notes: notes,
      isEnabled: true,
    );

    saveReminder(newReminder);
  }

  void saveLocalOrderPreview({
    required String deliveryAddress,
    required List<String> items,
    required int totalAmount,
  }) {
    final now = DateTime.now();
    final preview = CareOrder(
      orderId: 'PREVIEW-${now.millisecondsSinceEpoch}',
      orderDate: '${now.day}/${now.month}/${now.year}',
      estimatedDelivery: 'Not scheduled',
      status: 'Preview only · not submitted',
      currentStep: 0,
      courierName: '',
      trackingNumber: '',
      deliveryAddress: deliveryAddress,
      items: items,
      totalAmount: totalAmount,
    );
    emit(state.copyWith(orders: [preview, ...state.orders]));
    _persistOrders();
  }

  void addOrder(CareOrder order) {
    emit(state.copyWith(orders: [order, ...state.orders]));
    _persistOrders();
  }

  Future<List<CareOrder>> fetchPatientOrders({
    String? sessionToken,
    String? status,
  }) async {
    final token = sessionToken ?? _sessionToken;
    try {
      final serverOrders = await _commerceDataSource.fetchPatientOrders(
        token: token,
        status: status,
      );
      if (status == null || status.isEmpty) {
        emit(state.copyWith(orders: serverOrders));
        _persistOrders();
      }
      return serverOrders;
    } catch (_) {
      return [];
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason, String? sessionToken}) async {
    final token = sessionToken ?? _sessionToken;
    if (token == null || token.isEmpty) return false;
    try {
      final updatedOrder = await _commerceDataSource.cancelOrder(
        token: token,
        orderId: orderId,
        reason: reason,
      );
      if (updatedOrder != null) {
        final updatedList = state.orders.map((o) {
          return o.orderId == orderId ? updatedOrder : o;
        }).toList();
        emit(state.copyWith(orders: updatedList));
        _persistOrders();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _persistOrders() {
    AppLocalCache.instance.put(
      _ordersKey,
      jsonEncode(state.orders.map((item) => item.toJson()).toList()),
    );
  }

  static List<T>? _readList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  void _persistCheckIns() {
    AppLocalCache.instance.put(
      _checkInsKey,
      jsonEncode(state.checkIns.map((item) => item.toJson()).toList()),
    );
  }

  void _persistRoutineTasks() {
    AppLocalCache.instance.put(
      _routineTasksKey,
      jsonEncode(state.routineTasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearPersonalCareData() async {
    final service =
        _notificationService ?? await CareNotificationService.create();
    for (final reminder in state.reminders) {
      await service.cancelReminder(reminder.id);
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        checkIns: const [],
        routineTasks: const [],
        reminders: const [],
        routineCompletionDays: const [],
        orders: const [],
      ),
    );
    final cache = AppLocalCache.instance;
    for (final key in [
      _checkInsKey,
      'care_checkins_v1',
      _ordersKey,
      'care_orders_v1',
      _routineTasksKey,
      'care_routine_tasks_v1',
      'care_bookings_v1',
      _routineHistoryKey,
      'care_persisted_routine_v1',
      'care_persisted_reminders_v1',
      'care_persisted_routine_day_v1',
      'care_notification_permission_status',
    ]) {
      await cache.remove(key);
    }
    _patientId = null;
    _sessionToken = null;
    await cache.put(_careDataClearedKey, true);
  }

  /// Resets interactive care flows to their original demo fixtures.
  Future<void> resetForDemo() async {
    final service =
        _notificationService ?? await CareNotificationService.create();
    for (final reminder in state.reminders) {
      await service.cancelReminder(reminder.id);
    }

    final cache = AppLocalCache.instance;
    for (final key in [
      _checkInsKey,
      'care_bookings_v1',
      _ordersKey,
      _routineHistoryKey,
      _careDataClearedKey,
      'care_persisted_routine_v1',
      'care_persisted_reminders_v1',
      'care_persisted_routine_day_v1',
      'care_notification_permission_status',
    ]) {
      await cache.remove(key);
    }

    emit(const CareState());
    await _initPersistence();
  }

  // --- DIET & WATER ACTIONS ---
  void selectDietDay(int dayIndex) {
    emit(state.copyWith(currentDietDay: dayIndex));
  }

  void toggleDietMeal(int dayIndex, int mealIndex) {
    if (dayIndex >= state.dietPlans.length) return;
    final dayMeals = List<DietMeal>.from(state.dietPlans[dayIndex]);
    if (mealIndex >= dayMeals.length) return;

    dayMeals[mealIndex] = dayMeals[mealIndex].copyWith(
      isCompleted: !dayMeals[mealIndex].isCompleted,
    );

    final updatedPlans = List<List<DietMeal>>.from(state.dietPlans);
    updatedPlans[dayIndex] = dayMeals;

    emit(state.copyWith(dietPlans: updatedPlans));
  }

  void incrementWater() {
    emit(state.copyWith(waterCups: (state.waterCups + 1).clamp(0, 12)));
  }

  void decrementWater() {
    emit(state.copyWith(waterCups: (state.waterCups - 1).clamp(0, 12)));
  }
}
