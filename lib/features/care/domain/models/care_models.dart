import 'package:flutter/material.dart';

/// Represents a photo check-in entry for scalp and hair progression tracking.
class ProgressCheckIn {
  final String id;
  final DateTime date;
  final String imagePath;
  final String? frontImagePath;
  final String? backImagePath;
  final String? topImagePath;
  final String scalpRegion;
  final String sheddingLevel;
  final String notes;
  final int densityRating;
  final bool isDoctorReviewed;
  final String? doctorNote;

  const ProgressCheckIn({
    required this.id,
    required this.date,
    required this.imagePath,
    this.frontImagePath,
    this.backImagePath,
    this.topImagePath,
    required this.scalpRegion,
    required this.sheddingLevel,
    this.notes = '',
    this.densityRating = 4,
    this.isDoctorReviewed = false,
    this.doctorNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'imagePath': imagePath,
    'frontImagePath': frontImagePath,
    'backImagePath': backImagePath,
    'topImagePath': topImagePath,
    'scalpRegion': scalpRegion,
    'sheddingLevel': sheddingLevel,
    'notes': notes,
    'densityRating': densityRating,
    'isDoctorReviewed': isDoctorReviewed,
    'doctorNote': doctorNote,
  };

  factory ProgressCheckIn.fromJson(Map<String, dynamic> json) => ProgressCheckIn(
    id: json['id'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    imagePath: json['imagePath'] as String? ?? '',
    frontImagePath: json['frontImagePath'] as String?,
    backImagePath: json['backImagePath'] as String?,
    topImagePath: json['topImagePath'] as String?,
    scalpRegion: json['scalpRegion'] as String? ?? 'Scalp',
    sheddingLevel: json['sheddingLevel'] as String? ?? 'Not recorded',
    notes: json['notes'] as String? ?? '',
    densityRating: (json['densityRating'] as num?)?.toInt() ?? 3,
    isDoctorReviewed: json['isDoctorReviewed'] as bool? ?? false,
    doctorNote: json['doctorNote'] as String?,
  );

  String get effectiveFrontImage => frontImagePath ?? imagePath;
  String get effectiveTopImage => topImagePath ?? imagePath;
  String get effectiveBackImage => backImagePath ?? imagePath;

  ProgressCheckIn copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    String? frontImagePath,
    String? backImagePath,
    String? topImagePath,
    String? scalpRegion,
    String? sheddingLevel,
    String? notes,
    int? densityRating,
    bool? isDoctorReviewed,
    String? doctorNote,
  }) {
    return ProgressCheckIn(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      topImagePath: topImagePath ?? this.topImagePath,
      scalpRegion: scalpRegion ?? this.scalpRegion,
      sheddingLevel: sheddingLevel ?? this.sheddingLevel,
      notes: notes ?? this.notes,
      densityRating: densityRating ?? this.densityRating,
      isDoctorReviewed: isDoctorReviewed ?? this.isDoctorReviewed,
      doctorNote: doctorNote ?? this.doctorNote,
    );
  }
}

/// Represents an interactive daily task in the hair care regimen.
class RoutineTask {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String timeOfDay;
  final bool isCompleted;

  const RoutineTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timeOfDay,
    this.isCompleted = false,
  });

  RoutineTask copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    String? timeOfDay,
    bool? isCompleted,
  }) {
    return RoutineTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'timeOfDay': timeOfDay,
      'isCompleted': isCompleted,
    };
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    return RoutineTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? '',
      timeOfDay: json['timeOfDay'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// Represents a scheduled notification reminder.
class CareReminder {
  final String id;
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final bool isEnabled;
  final String frequency;
  final String treatmentType;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday
  final bool isCompleted;
  final String notes;
  final DateTime? snoozedUntil;

  const CareReminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isEnabled = true,
    this.frequency = 'Daily',
    this.treatmentType = 'Topical Serum',
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isCompleted = false,
    this.notes = '',
    this.snoozedUntil,
  });

  bool get isSnoozed {
    if (snoozedUntil == null) return false;
    return DateTime.now().isBefore(snoozedUntil!);
  }

  String get daysSummary {
    if (repeatDays.isEmpty || repeatDays.length == 7) {
      return 'Daily';
    }
    final sorted = List<int>.from(repeatDays)..sort();
    if (sorted.length == 5 &&
        sorted[0] == 1 &&
        sorted[1] == 2 &&
        sorted[2] == 3 &&
        sorted[3] == 4 &&
        sorted[4] == 5) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted[0] == 6 && sorted[1] == 7) {
      return 'Weekends';
    }

    const dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return sorted.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');
  }

  String get timeFormatted {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0
        ? 12
        : (hour > 12 ? hour - 12 : hour);
    return '$formattedHour:$minute $period';
  }

  CareReminder copyWith({
    String? id,
    String? title,
    String? subtitle,
    TimeOfDay? time,
    bool? isEnabled,
    String? frequency,
    String? treatmentType,
    List<int>? repeatDays,
    bool? isCompleted,
    String? notes,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
  }) {
    return CareReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      treatmentType: treatmentType ?? this.treatmentType,
      repeatDays: repeatDays ?? this.repeatDays,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
      'frequency': frequency,
      'treatmentType': treatmentType,
      'repeatDays': repeatDays,
      'isCompleted': isCompleted,
      'notes': notes,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }

  factory CareReminder.fromJson(Map<String, dynamic> json) {
    return CareReminder(
      id: json['id'] as String? ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      frequency: json['frequency'] as String? ?? 'Daily',
      treatmentType: json['treatmentType'] as String? ?? 'Topical Serum',
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.tryParse(json['snoozedUntil'] as String)
          : null,
    );
  }
}

/// Represents a scheduled guidance consultation with a specialist.
class CoachBooking {
  final String id;
  final String coachName;
  final String role;
  final String avatarUrl;
  final DateTime date;
  final String timeSlot;
  final String consultationType;
  final String status;
  final String notes;

  const CoachBooking({
    required this.id,
    required this.coachName,
    required this.role,
    required this.avatarUrl,
    required this.date,
    required this.timeSlot,
    required this.consultationType,
    this.status = 'Confirmed',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'coachName': coachName,
    'role': role,
    'avatarUrl': avatarUrl,
    'date': date.toIso8601String(),
    'timeSlot': timeSlot,
    'consultationType': consultationType,
    'status': status,
    'notes': notes,
  };

  factory CoachBooking.fromJson(Map<String, dynamic> json) => CoachBooking(
    id: json['id'] as String? ?? '',
    coachName: json['coachName'] as String? ?? '',
    role: json['role'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    timeSlot: json['timeSlot'] as String? ?? '',
    consultationType: json['consultationType'] as String? ?? '',
    status: json['status'] as String? ?? 'Confirmed',
    notes: json['notes'] as String? ?? '',
  );

  CoachBooking copyWith({
    String? id,
    String? coachName,
    String? role,
    String? avatarUrl,
    DateTime? date,
    String? timeSlot,
    String? consultationType,
    String? status,
    String? notes,
  }) {
    return CoachBooking(
      id: id ?? this.id,
      coachName: coachName ?? this.coachName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      consultationType: consultationType ?? this.consultationType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

/// Represents a meal inside the daily hair nutrition guide.
class DietMeal {
  final String type;
  final String name;
  final String nutrients;
  final String benefit;
  final bool isCompleted;

  const DietMeal({
    required this.type,
    required this.name,
    required this.nutrients,
    required this.benefit,
    this.isCompleted = false,
  });

  DietMeal copyWith({
    String? type,
    String? name,
    String? nutrients,
    String? benefit,
    bool? isCompleted,
  }) {
    return DietMeal(
      type: type ?? this.type,
      name: name ?? this.name,
      nutrients: nutrients ?? this.nutrients,
      benefit: benefit ?? this.benefit,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Represents an active product shipment with tracking timeline.
class CareOrder {
  final String orderId;
  final String orderDate;
  final String estimatedDelivery;
  final String status;
  final int currentStep;
  final String courierName;
  final String trackingNumber;
  final String deliveryAddress;
  final List<String> items;
  final int totalAmount;

  const CareOrder({
    required this.orderId,
    required this.orderDate,
    required this.estimatedDelivery,
    required this.status,
    required this.currentStep,
    required this.courierName,
    required this.trackingNumber,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderDate': orderDate,
    'estimatedDelivery': estimatedDelivery,
    'status': status,
    'currentStep': currentStep,
    'courierName': courierName,
    'trackingNumber': trackingNumber,
    'deliveryAddress': deliveryAddress,
    'items': items,
    'totalAmount': totalAmount,
  };

  factory CareOrder.fromJson(Map<String, dynamic> json) => CareOrder(
    orderId: json['orderId'] as String? ?? '',
    orderDate: json['orderDate'] as String? ?? '',
    estimatedDelivery: json['estimatedDelivery'] as String? ?? '',
    status: json['status'] as String? ?? '',
    currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
    courierName: json['courierName'] as String? ?? '',
    trackingNumber: json['trackingNumber'] as String? ?? '',
    deliveryAddress: json['deliveryAddress'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? const []).cast<String>(),
    totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
  );
}
