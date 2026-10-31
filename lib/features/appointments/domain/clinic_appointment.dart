class ClinicAppointment {
  final String id;
  final String patientId;
  final DateTime startsAt;
  final String reason;
  final String status;

  const ClinicAppointment({
    required this.id,
    required this.patientId,
    required this.startsAt,
    required this.reason,
    this.status = 'Requested',
  });

  ClinicAppointment copyWith({DateTime? startsAt, String? status}) =>
      ClinicAppointment(
        id: id,
        patientId: patientId,
        startsAt: startsAt ?? this.startsAt,
        reason: reason,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'startsAt': startsAt.toIso8601String(),
    'reason': reason,
    'status': status,
  };

  static ClinicAppointment? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final patientId = value['patientId'];
    final startsAt = DateTime.tryParse(value['startsAt']?.toString() ?? '');
    final reason = value['reason'];
    final status = value['status'];
    if (id is! String ||
        patientId is! String ||
        startsAt == null ||
        reason is! String) {
      return null;
    }
    return ClinicAppointment(
      id: id,
      patientId: patientId,
      startsAt: startsAt,
      reason: reason,
      status: status is String && status.isNotEmpty ? status : 'Requested',
    );
  }
}
