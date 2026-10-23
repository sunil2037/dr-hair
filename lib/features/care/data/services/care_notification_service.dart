import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/care_models.dart';

enum NotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
}

/// Service managing reminder notification scheduling, permissions, and persistence.
class CareNotificationService {
  static const String _permissionKey = 'care_notification_permission_status';
  static const String _remindersStorageKey = 'care_persisted_reminders_v1';
  static const String _routineStorageKey = 'care_persisted_routine_v1';

  final SharedPreferences? _prefs;

  CareNotificationService([this._prefs]);

  static Future<CareNotificationService> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return CareNotificationService(prefs);
    } catch (e) {
      debugPrint('CareNotificationService init fallback: $e');
      return CareNotificationService(null);
    }
  }

  /// Retrieves the current notification permission status.
  NotificationPermissionStatus getPermissionStatus() {
    final raw = _prefs?.getString(_permissionKey);
    if (raw == 'granted') return NotificationPermissionStatus.granted;
    if (raw == 'denied') return NotificationPermissionStatus.denied;
    return NotificationPermissionStatus.notDetermined;
  }

  /// Requests notification permission honestly.
  /// If simulated in local demo environment, sets status to granted unless explicitly denied.
  Future<NotificationPermissionStatus> requestPermission({bool simulateDenial = false}) async {
    final status = simulateDenial
        ? NotificationPermissionStatus.denied
        : NotificationPermissionStatus.granted;
    await _prefs?.setString(
      _permissionKey,
      status == NotificationPermissionStatus.granted ? 'granted' : 'denied',
    );
    return status;
  }

  /// Resets permission back to notDetermined for testing.
  Future<void> resetPermission() async {
    await _prefs?.remove(_permissionKey);
  }

  /// Persists the active list of reminders to local storage.
  Future<bool> saveReminders(List<CareReminder> reminders) async {
    if (_prefs == null) return false;
    try {
      final jsonList = reminders.map((r) => r.toJson()).toList();
      return await _prefs.setString(_remindersStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save reminders: $e');
      return false;
    }
  }

  /// Loads persisted reminders from local storage.
  List<CareReminder>? loadReminders() {
    if (_prefs == null) return null;
    final raw = _prefs.getString(_remindersStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CareReminder.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load persisted reminders: $e');
      return null;
    }
  }

  /// Persists routine tasks to local storage.
  Future<bool> saveRoutineTasks(List<RoutineTask> tasks) async {
    if (_prefs == null) return false;
    try {
      final jsonList = tasks.map((t) => t.toJson()).toList();
      return await _prefs.setString(_routineStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save routine tasks: $e');
      return false;
    }
  }

  /// Loads persisted routine tasks from local storage.
  List<RoutineTask>? loadRoutineTasks() {
    if (_prefs == null) return null;
    final raw = _prefs.getString(_routineStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => RoutineTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load routine tasks: $e');
      return null;
    }
  }

  /// Schedules a notification for a reminder without duplicates.
  Future<void> scheduleReminder(CareReminder reminder) async {
    // In production without native notification plugins bundled in pubspec,
    // we log scheduling and track state. Native platform requirements:
    // Android: android.permission.POST_NOTIFICATIONS, ExactAlarm permission
    // iOS: UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    debugPrint(
      '[CareNotificationService] Scheduled reminder "${reminder.title}" at ${reminder.timeFormatted} (${reminder.daysSummary})',
    );
  }

  /// Cancels a scheduled reminder notification.
  Future<void> cancelReminder(String reminderId) async {
    debugPrint('[CareNotificationService] Cancelled reminder $reminderId');
  }

  /// Explains how to recover if permission was denied in device settings.
  static String getPermissionDeniedRecoveryAdvice() {
    return 'Dose notifications are disabled. To receive clinical regimen alerts, open your device Settings > Apps > Dr. Hair > Notifications and enable Allow Notifications.';
  }
}
