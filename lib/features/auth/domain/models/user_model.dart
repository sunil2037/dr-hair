class UserModel {
  final String id;
  final String name;
  final String emailOrPhone;
  final String patientId;
  final bool isGuest;
  final DateTime? loggedInAt;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.emailOrPhone,
    this.patientId = 'DRH-2024-8849',
    this.isGuest = false,
    this.loggedInAt,
    this.photoUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? emailOrPhone,
    String? patientId,
    bool? isGuest,
    DateTime? loggedInAt,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      patientId: patientId ?? this.patientId,
      isGuest: isGuest ?? this.isGuest,
      loggedInAt: loggedInAt ?? this.loggedInAt,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }

  static UserModel demoPatient({String? identifier}) {
    return UserModel(
      id: 'USR-8849',
      name: 'Yashveer Soni',
      emailOrPhone: identifier ?? '+91 98765 43210',
      patientId: 'DRH-2024-8849',
      isGuest: false,
      loggedInAt: DateTime.now(),
    );
  }

  static UserModel guest() {
    return UserModel(
      id: 'GUEST-001',
      name: 'Guest User',
      emailOrPhone: 'guest@drhair.com',
      patientId: 'GUEST',
      isGuest: true,
      loggedInAt: DateTime.now(),
    );
  }
}
