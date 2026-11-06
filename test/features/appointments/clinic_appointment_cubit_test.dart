import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/storage/app_local_cache.dart';
import 'package:dr_hair/features/appointments/presentation/clinic_appointment_cubit.dart';

void main() {
  test(
    'saves, validates, cancels, and restores a physical visit request',
    () async {
      final cache = AppLocalCache.inMemory();
      final cubit = ClinicAppointmentCubit(cache: cache);
      final time = DateTime.now().add(const Duration(days: 2));
      expect(
        await cubit.saveRequest(
          patientId: 'PAT-1',
          startsAt: time,
          reason: 'Scalp scan',
          consultationFee: 500,
          paymentMethod: 'UPI',
          paymentStatus: 'Paid',
          paymentTransactionId: 'TXN-TEST-1234',
        ),
        isNull,
      );
      expect(cubit.forPatient('PAT-1'), hasLength(1));
      final apt = cubit.forPatient('PAT-1').first;
      expect(apt.consultationFee, 500);
      expect(apt.paymentStatus, 'Paid');
      expect(apt.paymentMethod, 'UPI');
      expect(apt.tokenNumber.isNotEmpty, true);
      expect(
        await cubit.saveRequest(
          patientId: 'PAT-1',
          startsAt: time.add(const Duration(minutes: 10)),
          reason: 'Follow-up visit',
        ),
        isNotNull,
      );
      expect(cubit.forPatient('PAT-1'), hasLength(1));
      final id = cubit.forPatient('PAT-1').first.id;
      final restored = ClinicAppointmentCubit(cache: cache)..load();
      expect(restored.forPatient('PAT-1').single.id, id);
      await restored.cancel(id, 'PAT-1');
      expect(restored.forPatient('PAT-1').single.status, 'Cancelled');
      await restored.clearForPatient('PAT-1');
      expect(restored.forPatient('PAT-1'), isEmpty);
      await cubit.close();
      await restored.close();
    },
  );

  test('reschedules appointment slot with optimistic update and persistence', () async {
    final cache = AppLocalCache.inMemory();
    final cubit = ClinicAppointmentCubit(cache: cache);
    final initialTime = DateTime.now().add(const Duration(days: 3));

    await cubit.saveRequest(
      patientId: 'PAT-1',
      startsAt: initialTime,
      reason: 'Scalp scan',
    );

    final appointmentId = cubit.forPatient('PAT-1').first.id;
    final newSlot = DateTime.now().add(const Duration(days: 5));

    final result = await cubit.reschedule(
      id: appointmentId,
      patientId: 'PAT-1',
      newStartsAt: newSlot,
    );

    expect(result, isNull);
    final updated = cubit.forPatient('PAT-1').first;
    expect(updated.startsAt, newSlot);
    expect(updated.status, 'Requested');

    // Verify persistence
    final restored = ClinicAppointmentCubit(cache: cache)..load();
    expect(restored.forPatient('PAT-1').first.startsAt, newSlot);
    expect(restored.forPatient('PAT-1').first.status, 'Requested');

    // Verify rejection if slot is in the past or < 1 hr
    final invalidPast = DateTime.now().subtract(const Duration(hours: 2));
    final errorPast = await cubit.reschedule(
      id: appointmentId,
      patientId: 'PAT-1',
      newStartsAt: invalidPast,
    );
    expect(errorPast, isNotNull);

    await cubit.close();
    await restored.close();
  });
}
