import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/app_destination.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final AppDestination destination;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.destination,
    this.data = const {},
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    final rawDest = json['destination'];
    final destMap = rawDest is Map<String, dynamic>
        ? rawDest
        : <String, dynamic>{
            'destination_type': json['type'],
            'screen': json['screen'],
            'entity_id': json['entity_id'] ?? json['entityId'],
          };

    return NotificationItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      destination: AppDestination.fromJson(destMap),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      imageUrl: json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          json['image']?.toString(),
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationItemModel copyWith({bool? isRead, String? imageUrl}) {
    return NotificationItemModel(
      id: id,
      title: title,
      body: body,
      type: type,
      destination: destination,
      data: data,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  IconData get iconData {
    return switch (type) {
      'appointment' => LucideIcons.calendarCheck,
      'order' => LucideIcons.packageCheck,
      'product' => LucideIcons.shoppingBag,
      'treatment' => LucideIcons.stethoscope,
      'reminder' => LucideIcons.sparkles,
      'announcement' => LucideIcons.megaphone,
      _ => LucideIcons.bell,
    };
  }

  Color get iconColor {
    return switch (type) {
      'appointment' => const Color(0xFF0F9F8F),
      'order' => const Color(0xFF0F9F8F),
      'product' => const Color(0xFF3876C5),
      'treatment' => const Color(0xFF3876C5),
      'reminder' => const Color(0xFF9A69C7),
      'announcement' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };
  }

  String get formattedTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
