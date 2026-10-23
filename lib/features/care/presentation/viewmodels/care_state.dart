import '../../data/services/care_notification_service.dart';
import '../../domain/models/care_models.dart';

class CareState {
  final List<ProgressCheckIn> checkIns;
  final List<RoutineTask> routineTasks;
  final List<CareReminder> reminders;
  final List<CoachBooking> coachBookings;
  final List<List<DietMeal>> dietPlans;
  final int currentDietDay;
  final int waterCups;
  final List<CareOrder> orders;
  final NotificationPermissionStatus notificationPermissionStatus;
  final bool isLoadingReminders;

  const CareState({
    this.checkIns = const [],
    this.routineTasks = const [],
    this.reminders = const [],
    this.coachBookings = const [],
    this.dietPlans = const [],
    this.currentDietDay = 0,
    this.waterCups = 6,
    this.orders = const [],
    this.notificationPermissionStatus = NotificationPermissionStatus.notDetermined,
    this.isLoadingReminders = false,
  });

  int get completedRoutineCount =>
      routineTasks.where((t) => t.isCompleted).length;

  double get routineProgress =>
      routineTasks.isEmpty ? 0 : completedRoutineCount / routineTasks.length;

  int get routineStreakDays => 14;

  CareState copyWith({
    List<ProgressCheckIn>? checkIns,
    List<RoutineTask>? routineTasks,
    List<CareReminder>? reminders,
    List<CoachBooking>? coachBookings,
    List<List<DietMeal>>? dietPlans,
    int? currentDietDay,
    int? waterCups,
    List<CareOrder>? orders,
    NotificationPermissionStatus? notificationPermissionStatus,
    bool? isLoadingReminders,
  }) {
    return CareState(
      checkIns: checkIns ?? this.checkIns,
      routineTasks: routineTasks ?? this.routineTasks,
      reminders: reminders ?? this.reminders,
      coachBookings: coachBookings ?? this.coachBookings,
      dietPlans: dietPlans ?? this.dietPlans,
      currentDietDay: currentDietDay ?? this.currentDietDay,
      waterCups: waterCups ?? this.waterCups,
      orders: orders ?? this.orders,
      notificationPermissionStatus:
          notificationPermissionStatus ?? this.notificationPermissionStatus,
      isLoadingReminders: isLoadingReminders ?? this.isLoadingReminders,
    );
  }
}
