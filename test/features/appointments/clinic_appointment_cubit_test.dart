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
}
