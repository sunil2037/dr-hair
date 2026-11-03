import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small typed facade over Hive for app data that should survive restarts.
class AppLocalCache {
  AppLocalCache._({this._box, this._memoryStore});

  static const String boxName = 'dr_hair_cache';
  static const String _migrationKey = 'legacy_preferences_migrated_v1';
  static const List<String> _legacyKeys = [
    'has_completed_hair_test',
    'hair_test_stage',
    'hair_test_dandruff',
    'hair_test_name',
    'hair_test_age',
    'care_notification_permission_status',
    'care_persisted_reminders_v1',
    'care_persisted_routine_v1',
  ];
  static Box<dynamic>? _sharedBox;
  static final Map<String, Object?> _fallbackMemoryStore = <String, Object?>{};

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memoryStore;

  static AppLocalCache get instance =>
      AppLocalCache._(box: _sharedBox, memoryStore: _sharedBox == null ? _fallbackMemoryStore : null);

  @visibleForTesting
  factory AppLocalCache.inMemory([Map<String, Object?>? values]) =>
      AppLocalCache._(memoryStore: values ?? <String, Object?>{});

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _sharedBox = await Hive.openBox<dynamic>(boxName);
    await _migrateLegacyPreferences(_sharedBox!);
  }

  static Future<void> _migrateLegacyPreferences(Box<dynamic> box) async {
    if (box.get(_migrationKey) == true) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      for (final key in _legacyKeys) {
        final value = preferences.get(key);
        if (value != null && !box.containsKey(key)) {
          await box.put(key, value);
        }
        if (value != null) await preferences.remove(key);
      }
      await box.put(_migrationKey, true);
    } catch (error) {
      debugPrint('Could not migrate legacy local data to Hive: $error');
    }
  }

  Object? get(String key) => _box?.get(key) ?? _memoryStore?[key];

  String? getString(String key) => get(key) as String?;

  bool? getBool(String key) => get(key) as bool?;

  Future<void> put(String key, Object value) async {
    if (_box != null) {
      await _box.put(key, value);
    } else {
      _memoryStore?[key] = value;
    }
  }

  Future<void> remove(String key) async {
    if (_box != null) {
      await _box.delete(key);
    } else {
      _memoryStore?.remove(key);
    }
  }

  /// Generates a namespaced key for patient-specific state.
  static String patientKey(String patientId, String key) {
    final cleanId = patientId.trim();
    return cleanId.isNotEmpty ? 'patient_${cleanId}_$key' : key;
  }

  /// Removes all persisted keys belonging specifically to the given patient.
  Future<void> clearPatientScopedData(String patientId) async {
    final cleanId = patientId.trim();
    if (cleanId.isEmpty) return;
    final prefix = 'patient_${cleanId}_';

    final box = _box;
    if (box != null) {
      final keysToRemove = box.keys
          .map((k) => k.toString())
          .where((k) => k.startsWith(prefix) || k.contains(cleanId))
          .toList();
      for (final key in keysToRemove) {
        await box.delete(key);
      }
    }
    final memoryStore = _memoryStore;
    if (memoryStore != null) {
      memoryStore.removeWhere((k, _) => k.startsWith(prefix) || k.contains(cleanId));
    }
  }

  /// Clears app-persisted user state while keeping migration from rerunning.
  Future<void> clearAll() async {
    if (_box != null) {
      await _box.clear();
      await _box.put(_migrationKey, true);
      final preferences = await SharedPreferences.getInstance();
      for (final key in _legacyKeys) {
        await preferences.remove(key);
      }
    } else {
      _memoryStore?.clear();
      _memoryStore?[_migrationKey] = true;
    }
  }
}
