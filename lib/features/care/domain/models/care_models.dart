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
    this.isDoctorReviewed = true,
    this.doctorNote,
  });

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
}

/// Represents a scheduled notification reminder.
class CareReminder {
  final String id;
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final bool isEnabled;
  final String frequency;

  const CareReminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isEnabled = true,
    this.frequency = 'Daily',
  });

  CareReminder copyWith({
    String? id,
    String? title,
    String? subtitle,
    TimeOfDay? time,
    bool? isEnabled,
    String? frequency,
  }) {
    return CareReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
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
}
