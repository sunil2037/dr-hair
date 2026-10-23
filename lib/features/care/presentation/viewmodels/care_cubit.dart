import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/care_notification_service.dart';
import '../../domain/models/care_models.dart';
import 'care_state.dart';

class CareCubit extends Cubit<CareState> {
  final CareNotificationService? _notificationService;

  CareCubit([this._notificationService]) : super(const CareState()) {
    _initializeDefaultData();
    _initPersistence();
  }

  Future<void> _initPersistence() async {
    final service = _notificationService ?? await CareNotificationService.create();
    final status = service.getPermissionStatus();
    final persistedReminders = service.loadReminders();
    final persistedTasks = service.loadRoutineTasks();

    emit(
      state.copyWith(
        notificationPermissionStatus: status,
        reminders: persistedReminders ?? state.reminders,
        routineTasks: persistedTasks ?? state.routineTasks,
      ),
    );
  }

  void _initializeDefaultData() {
    final defaultCheckIns = [
      ProgressCheckIn(
        id: 'ci_1',
        date: DateTime.now().subtract(const Duration(days: 4)),
        imagePath:
            'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=600',
        scalpRegion: 'Crown / Vertex',
        sheddingLevel: 'Low / Normal',
        notes:
            'Noticeable increase in hair shaft thickness. Baby hairs visible around follicle borders.',
        densityRating: 4,
        isDoctorReviewed: true,
        doctorNote:
            'Follicular miniaturization is reversing nicely. Maintain current 5% topical solution frequency.',
      ),
      ProgressCheckIn(
        id: 'ci_2',
        date: DateTime.now().subtract(const Duration(days: 35)),
        imagePath:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600',
        scalpRegion: 'Frontal Hairline',
        sheddingLevel: 'Moderate',
        notes:
            'Shedding during evening shampoo significantly reduced. Scalp irritation is gone.',
        densityRating: 3,
        isDoctorReviewed: true,
        doctorNote:
            'Good cellular response to the DHT blocker. Consistency is key during month 2-3.',
      ),
      ProgressCheckIn(
        id: 'ci_3',
        date: DateTime.now().subtract(const Duration(days: 75)),
        imagePath:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600',
        scalpRegion: 'Crown / Vertex',
        sheddingLevel: 'Noticeable',
        notes:
            'Baseline consultation photo before starting customized formulation.',
        densityRating: 2,
        isDoctorReviewed: true,
        doctorNote:
            'Baseline captured. Target: Stage 2 androgenetic thinning.',
      ),
    ];

    final defaultTasks = [
      const RoutineTask(
        id: 'rt_1',
        title: 'Dr.Hair 5% Topical Regrowth Booster',
        subtitle: 'Apply 1ml with dropper evenly on crown and hairline',
        category: 'Clinical Topical',
        timeOfDay: 'Evening',
        isCompleted: true,
      ),
      const RoutineTask(
        id: 'rt_2',
        title: 'Biotin & Saw Palmetto Complex',
        subtitle: '1 tablet post-breakfast with water',
        category: 'Oral Supplement',
        timeOfDay: 'Morning',
        isCompleted: true,
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

    final defaultBookings = [
      CoachBooking(
        id: 'cb_1',
        coachName: 'Dr. Priya Verma',
        role: 'Senior Trichologist & Clinical Lead',
        avatarUrl:
            'https://images.unsplash.com/photo-1594824813637-883a9e652a6a?q=80&w=300',
        date: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '11:30 AM',
        consultationType: 'Video Consultation (15 mins)',
        status: 'Confirmed',
        notes: 'Month 2 routine adjustment and scalp density review.',
      ),
    ];

    final defaultDiet = [
      // Day 1: High Protein & Keratin
      [
        const DietMeal(
          type: 'Breakfast',
          name: 'Sprouted Moong & Paneer Omelette / Scramble',
          nutrients: 'Protein (22g) · Biotin · Iron',
          benefit:
              'Provides sulfur-rich amino acids required to produce keratin protein chains.',
          isCompleted: true,
        ),
        const DietMeal(
          type: 'Lunch',
          name: 'Palak Dal with Brown Rice & Raw Salad',
          nutrients: 'Folate · Zinc · Plant Iron',
          benefit:
              'Enhances red blood cell hemoglobin for optimal oxygen supply to roots.',
          isCompleted: true,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Roasted Pumpkin & Sunflower Seeds with Walnuts',
          nutrients: 'Omega-3 · Zinc · Magnesium',
          benefit:
              'Natural 5-alpha reductase enzyme inhibitor to counter follicular sensitivity.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Steamed Greens with Soya Chunks or Grilled Fish',
          nutrients: 'Keratin building blocks · Vitamin E',
          benefit:
              'Supports nocturnal follicle matrix cellular regeneration.',
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
          benefit:
              'Aids DNA replication and active anagen phase elongation.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Amla (Indian Gooseberry) Juice with Flax Crackers',
          nutrients: 'Vitamin C · Collagen Co-factor',
          benefit:
              'Powers scalp collagen synthesis and increases non-heme iron absorption.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Mixed Vegetable Khichdi with Ghee & Curd',
          nutrients: 'Butyric acid · Probiotics',
          benefit:
              'Healthy gut microbiome ensures complete micronutrient assimilation.',
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
          benefit:
              'Strengthens hair shafts and minimizes breakage.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Evening Snack',
          name: 'Greek Yogurt with Crushed Brazil Nuts',
          nutrients: 'Selenium · Calcium',
          benefit:
              'Supports thyroid hormone balance vital for healthy shedding cycle.',
          isCompleted: false,
        ),
        const DietMeal(
          type: 'Dinner',
          name: 'Paneer / Tofu Bhurji with Sauted Bell Peppers',
          nutrients: 'Vitamin A · Carotenoids',
          benefit:
              'Normalizes sebum secretion across scalp for healthy follicle breathing.',
          isCompleted: false,
        ),
      ],
    ];

    final defaultOrders = [
      const CareOrder(
        orderId: 'DRH-99214',
        orderDate: 'Oct 20, 2026',
        estimatedDelivery: 'Oct 23, 2026 (Tomorrow)',
        status: 'Out for Delivery',
        currentStep: 3,
        courierName: 'BlueDart Express',
        trackingNumber: 'BD-884910245IN',
        deliveryAddress:
            'Apt 402, Green Glen Layout, Bellandur, Bengaluru 560103',
        items: [
          'Dr.Hair Customized 5% Topical Regrowth Serum (60ml)',
          'DHT-Blocker Saw Palmetto & Biotin Capsules (60 Tabs)',
          'Anti-Residue Scalp Clarifying Cleanser (100ml)',
        ],
        totalAmount: 2048,
      ),
    ];

    emit(
      CareState(
        checkIns: defaultCheckIns,
        routineTasks: defaultTasks,
        reminders: defaultReminders,
        coachBookings: defaultBookings,
        dietPlans: defaultDiet,
        currentDietDay: 0,
        waterCups: 6,
        orders: defaultOrders,
      ),
    );
  }

  // --- PROGRESS CHECK-IN ACTIONS ---
  void addProgressCheckIn({
    required DateTime date,
    required String imagePath,
    String? frontImagePath,
    String? backImagePath,
    String? topImagePath,
    required String scalpRegion,
    required String sheddingLevel,
    required String notes,
    int densityRating = 4,
  }) {
    final newCheckIn = ProgressCheckIn(
      id: 'ci_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      imagePath: imagePath,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
      topImagePath: topImagePath,
      scalpRegion: scalpRegion,
      sheddingLevel: sheddingLevel,
      notes: notes,
      densityRating: densityRating,
      isDoctorReviewed: true,
      doctorNote: 'Clinical review pending. Photo logged successfully.',
    );

    emit(state.copyWith(checkIns: [newCheckIn, ...state.checkIns]));
  }

  void deleteProgressCheckIn(String id) {
    emit(
      state.copyWith(
        checkIns: state.checkIns.where((ci) => ci.id != id).toList(),
      ),
    );
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
    _notificationService?.saveRoutineTasks(updated);
  }

  void addCustomRoutineTask({
    required String title,
    required String subtitle,
    required String category,
    required String timeOfDay,
  }) {
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
    _notificationService?.saveRoutineTasks(updated);
  }

  void resetTodayRoutine() {
    final reset = state.routineTasks
        .map((task) => task.copyWith(isCompleted: false))
        .toList();
    emit(state.copyWith(routineTasks: reset));
    _notificationService?.saveRoutineTasks(reset);
  }

  // --- REMINDER ACTIONS ---
  Future<void> requestNotificationPermission({bool simulateDenial = false}) async {
    final service = _notificationService ?? await CareNotificationService.create();
    final status = await service.requestPermission(simulateDenial: simulateDenial);
    emit(state.copyWith(notificationPermissionStatus: status));
  }

  void saveReminder(CareReminder reminder) {
    final existingIndex = state.reminders.indexWhere((r) => r.id == reminder.id);
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

  void snoozeReminder(String id, {Duration duration = const Duration(minutes: 15)}) {
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
        return rem.copyWith(
          isCompleted: !rem.isCompleted,
          clearSnooze: true,
        );
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

  // --- COACH BOOKING ACTIONS ---
  void bookCoach({
    required String coachName,
    required String role,
    required String avatarUrl,
    required DateTime date,
    required String timeSlot,
    required String consultationType,
    required String notes,
  }) {
    final newBooking = CoachBooking(
      id: 'cb_${DateTime.now().millisecondsSinceEpoch}',
      coachName: coachName,
      role: role,
      avatarUrl: avatarUrl,
      date: date,
      timeSlot: timeSlot,
      consultationType: consultationType,
      status: 'Confirmed',
      notes: notes,
    );

    emit(state.copyWith(coachBookings: [newBooking, ...state.coachBookings]));
  }

  void cancelCoachBooking(String id) {
    final updated = state.coachBookings.map((b) {
      if (b.id == id) {
        return b.copyWith(status: 'Cancelled');
      }
      return b;
    }).toList();

    emit(state.copyWith(coachBookings: updated));
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
