class ClinicAppointment {
  final String id;
  final String patientId;
  final DateTime startsAt;
  final String reason;
  final String status;
  final String tokenNumber;
  final String doctorName;
  final String room;
  final int consultationFee;
  final String paymentStatus;
  final String paymentMethod;
  final String paymentTransactionId;

  const ClinicAppointment({
    required this.id,
    required this.patientId,
    required this.startsAt,
    required this.reason,
    this.status = 'Requested',
    this.tokenNumber = '',
    this.doctorName = 'Dr. Jai Bansal',
    this.room = 'Room 101 - Chamber A',
    this.consultationFee = 500,
    this.paymentStatus = 'Pending',
    this.paymentMethod = 'UPI',
    this.paymentTransactionId = '',
  });

  ClinicAppointment copyWith({
    DateTime? startsAt,
    String? status,
    String? tokenNumber,
    int? consultationFee,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentTransactionId,
  }) => ClinicAppointment(
    id: id,
    patientId: patientId,
    startsAt: startsAt ?? this.startsAt,
    reason: reason,
    status: status ?? this.status,
    tokenNumber: tokenNumber ?? this.tokenNumber,
    doctorName: doctorName,
    room: room,
    consultationFee: consultationFee ?? this.consultationFee,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'startsAt': startsAt.toIso8601String(),
    'reason': reason,
    'status': status,
    'tokenNumber': tokenNumber,
    'doctorName': doctorName,
    'room': room,
    'consultationFee': consultationFee,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'paymentTransactionId': paymentTransactionId,
  };

  static ClinicAppointment? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id']?.toString() ?? value['_id']?.toString() ?? '';
    final patientId = value['patientId']?.toString() ??
        value['patient_code']?.toString() ??
        value['userId']?.toString() ??
        '';
    final startsAt = DateTime.tryParse(value['startsAt']?.toString() ?? value['starts_at']?.toString() ?? '');
    final reason = value['reason']?.toString() ?? value['service']?.toString() ?? 'General hair consultation';
    final status = value['status']?.toString() ?? value['opdStatus']?.toString() ?? 'Requested';
    final tokenNumber = value['tokenNumber']?.toString() ?? value['opd_token']?.toString() ?? '';
    final doctorName = value['doctorName']?.toString() ?? value['doctor_name']?.toString() ?? 'Dr. Jai Bansal';
    final room = value['room']?.toString() ?? 'Room 101 - Chamber A';
    final consultationFee = (value['consultationFee'] ?? value['consultation_fee']) is num
        ? ((value['consultationFee'] ?? value['consultation_fee']) as num).toInt()
        : 500;
    final paymentStatus = value['paymentStatus']?.toString() ?? value['payment_status']?.toString() ?? 'Pending';
    final paymentMethod = value['paymentMethod']?.toString() ?? value['payment_method']?.toString() ?? 'UPI';
    final paymentTransactionId = value['paymentTransactionId']?.toString() ?? value['payment_transaction_id']?.toString() ?? '';

    if (id.isEmpty || startsAt == null) {
      return null;
    }
    return ClinicAppointment(
      id: id,
      patientId: patientId,
      startsAt: startsAt,
      reason: reason,
      status: status.isNotEmpty ? status : 'Requested',
      tokenNumber: tokenNumber,
      doctorName: doctorName.isNotEmpty ? doctorName : 'Dr. Jai Bansal',
      room: room.isNotEmpty ? room : 'Room 101 - Chamber A',
      consultationFee: consultationFee,
      paymentStatus: paymentStatus.isNotEmpty ? paymentStatus : 'Pending',
      paymentMethod: paymentMethod.isNotEmpty ? paymentMethod : 'UPI',
      paymentTransactionId: paymentTransactionId,
    );
  }
}
