import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/app_local_cache.dart';
import '../domain/clinic_appointment.dart';

class ClinicAppointmentCubit extends Cubit<List<ClinicAppointment>> {
  static const storageKey = 'clinic_appointment_requests_v1';
  final AppLocalCache cache;

  ClinicAppointmentCubit({AppLocalCache? cache})
    : cache = cache ?? AppLocalCache.instance,
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

  List<ClinicAppointment> forPatient(String patientId) =>
      state.where((item) => item.patientId == patientId).toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  Future<String?> saveRequest({
    required String patientId,
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
    final appointment = ClinicAppointment(
      id: replacingId ?? 'APT-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patientId,
      startsAt: startsAt,
      reason: reason.trim(),
    );
    emit(
      replacingId == null
          ? [appointment, ...state]
          : state
                .map((item) => item.id == replacingId ? appointment : item)
                .toList(),
    );
    await _persist();
    return null;
  }

  Future<void> cancel(String id, String patientId) async {
    emit(
      state
          .map(
            (item) =>
                item.id == id &&
                    item.patientId == patientId &&
                    item.status != 'Cancelled'
                ? item.copyWith(status: 'Cancelled')
                : item,
          )
          .toList(),
    );
    await _persist();
  }

  Future<void> clearForPatient(String patientId) async {
    emit(state.where((item) => item.patientId != patientId).toList());
    await _persist();
  }

  Future<void> _persist() => cache.put(
    storageKey,
    jsonEncode(state.map((item) => item.toJson()).toList()),
  );
}
