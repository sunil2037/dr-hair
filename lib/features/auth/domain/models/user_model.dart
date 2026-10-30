class UserModel {
  final String id;
  final String name;
  final String emailOrPhone;
  final String? email;
  final String? phone;
  final String patientId;
  final int? age;
  final String? gender;
  final String? city;
  final String? occupation;
  final bool isGuest;
  final DateTime? loggedInAt;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.emailOrPhone,
    this.email,
    this.phone,
    this.patientId = 'DRH-2024-8849',
    this.age,
    this.gender,
    this.city,
    this.occupation,
    this.isGuest = false,
    this.loggedInAt,
    this.photoUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? emailOrPhone,
    String? email,
    String? phone,
    String? patientId,
    int? age,
    String? gender,
    String? city,
    String? occupation,
    bool? isGuest,
    DateTime? loggedInAt,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      occupation: occupation ?? this.occupation,
      isGuest: isGuest ?? this.isGuest,
      loggedInAt: loggedInAt ?? this.loggedInAt,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackLogin = '',
  }) {
    final id = json['id']?.toString() ?? '';
    final email = json['email']?.toString();
    final phone = json['phone']?.toString();
    final ageValue = json['age'];
    return UserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      emailOrPhone:
          (phone?.isNotEmpty == true ? phone : email) ?? fallbackLogin,
      email: email,
      phone: phone,
      patientId: id,
      age: ageValue == null ? null : int.tryParse(ageValue.toString()),
      gender: json['gender']?.toString(),
      city: json['city']?.toString(),
      occupation: json['occupation']?.toString(),
      photoUrl: json['profile_url']?.toString(),
      isGuest: false,
      loggedInAt: DateTime.now(),
    );
  }

  static UserModel demoPatient({String? identifier}) {
    return UserModel(
      id: 'USR-8849',
      name: 'Yashveer Soni',
      emailOrPhone: identifier ?? '+91 98765 43210',
      email: 'yashveer@example.com',
      phone: '+91 98765 43210',
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
      email: 'guest@drhair.com',
      phone: '',
      patientId: 'GUEST',
      isGuest: true,
      loggedInAt: DateTime.now(),
    );
  }
}
