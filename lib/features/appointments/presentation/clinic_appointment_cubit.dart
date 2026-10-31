import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/app_local_cache.dart';
import '../data/patient_appointment_api.dart';
import '../domain/clinic_appointment.dart';

class ClinicAppointmentCubit extends Cubit<List<ClinicAppointment>> {
  static const storageKey = 'clinic_appointment_requests_v1';
  final AppLocalCache cache;
  final PatientAppointmentApi api;
  bool isLoading = false;
  String? loadError;

  ClinicAppointmentCubit({AppLocalCache? cache, PatientAppointmentApi? api})
    : cache = cache ?? AppLocalCache.instance,
      api = api ?? PatientAppointmentApi(),
      super(const []);

  void load() {
    final raw = cache.getString(storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      emit(
        decoded
            .map(ClinicAppointment.fromJson)
            .whereType<ClinicAppointment>()
            .toList(),
      );
    } catch (_) {
      // A damaged local preview must not prevent the app from opening.
    }
  }

  Future<void> loadFromApi(String token) async {
    isLoading = true;
    loadError = null;
    try {
      final records = await api.list(token);
      emit(records.map(ClinicAppointment.fromJson).whereType<ClinicAppointment>().toList());
      await _persist();
    } catch (error) {
      loadError = error.toString();
    } finally {
      isLoading = false;
      emit(List<ClinicAppointment>.from(state));
    }
  }

  List<ClinicAppointment> forPatient(String patientId) =>
      state.where((item) => item.patientId == patientId).toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  Future<String?> saveRequest({
    required String patientId,
    required String accessToken,
    required DateTime startsAt,
    required String reason,
    String? replacingId,
  }) async {
    if (patientId.isEmpty || patientId == 'GUEST') {
      return 'Sign in to save an appointment request.';
    }
    if (startsAt.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      return 'Choose a time at least one hour from now.';
    }
    if (startsAt.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      return 'Choose a time within the next 90 days.';
    }
    if (reason.trim().isEmpty) return 'Choose a reason for your visit.';
    if (state.any(
      (item) =>
          item.patientId == patientId &&
          item.id != replacingId &&
          item.status != 'Cancelled' &&
          item.startsAt.difference(startsAt).inMinutes.abs() < 30,
    )) {
      return 'You already have a request close to this time.';
    }
    if (replacingId != null &&
        !state.any(
          (item) =>
              item.id == replacingId &&
              item.patientId == patientId &&
              item.status != 'Cancelled',
        )) {
      return 'This appointment request is no longer available.';
    }
    try {
      if (replacingId == null) {
        await api.create(token: accessToken, startsAt: startsAt, reason: reason.trim());
      } else {
        await api.update(
          token: accessToken,
          appointmentId: replacingId,
          data: {'action': 'reschedule', 'starts_at': startsAt.toUtc().toIso8601String()},
        );
      }
      await loadFromApi(accessToken);
      return null;
    } catch (error) {
      return _errorMessage(error, 'Appointment request could not be saved.');
    }
  }

  Future<String?> cancel(String id, String patientId, {required String accessToken}) async {
    try {
      await api.update(token: accessToken, appointmentId: id, data: {'action': 'cancel'});
      await loadFromApi(accessToken);
      return null;
    } catch (error) {
      return _errorMessage(error, 'Appointment request could not be cancelled.');
    }
  }

  Future<void> clearForPatient(String patientId) async {
    emit(state.where((item) => item.patientId != patientId).toList());
    await _persist();
  }

  Future<void> _persist() => cache.put(
    storageKey,
    jsonEncode(state.map((item) => item.toJson()).toList()),
  );

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final message = error.response?.data;
      if (message is Map && message['message'] is String) return message['message'] as String;
      return error.message ?? fallback;
    }
    return error is FormatException ? error.message : fallback;
  }
}
