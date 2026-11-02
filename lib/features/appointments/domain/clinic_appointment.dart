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
    final id = value['id'];
    final patientId = value['patientId'];
    final startsAt = DateTime.tryParse(value['startsAt']?.toString() ?? value['starts_at']?.toString() ?? '');
    final reason = value['reason'] ?? value['service'];
    final status = value['status'] ?? value['opdStatus'];
    final tokenNumber = value['tokenNumber'] ?? value['opd_token'] ?? '';
    final doctorName = value['doctorName'] ?? value['doctor_name'] ?? 'Dr. Jai Bansal';
    final room = value['room'] ?? 'Room 101 - Chamber A';
    final consultationFee = (value['consultationFee'] ?? value['consultation_fee']) is num
        ? ((value['consultationFee'] ?? value['consultation_fee']) as num).toInt()
        : 500;
    final paymentStatus = value['paymentStatus'] ?? value['payment_status'] ?? 'Pending';
    final paymentMethod = value['paymentMethod'] ?? value['payment_method'] ?? 'UPI';
    final paymentTransactionId = value['paymentTransactionId'] ?? value['payment_transaction_id'] ?? '';

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
      tokenNumber: tokenNumber is String ? tokenNumber : '',
      doctorName: doctorName is String ? doctorName : 'Dr. Jai Bansal',
      room: room is String ? room : 'Room 101 - Chamber A',
      consultationFee: consultationFee,
      paymentStatus: paymentStatus is String ? paymentStatus : 'Pending',
      paymentMethod: paymentMethod is String ? paymentMethod : 'UPI',
      paymentTransactionId: paymentTransactionId is String ? paymentTransactionId : '',
    );
  }
}
