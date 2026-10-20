import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final Set<int> _read = {};

  static const _notifications = [
    (
      LucideIcons.packageCheck,
      'Your order is on its way',
      'We’ll let you know when it reaches your doorstep.',
      'Today · 10:42 AM',
      Color(0xFF0F9F8F),
    ),
    (
      LucideIcons.stethoscope,
      'Your care plan is ready',
      'Your personalized routine is waiting in your profile.',
      'Yesterday · 6:18 PM',
      Color(0xFF3876C5),
    ),
    (
      LucideIcons.sparkles,
      'A little progress adds up',
      'Consistency is key. Remember your evening scalp routine.',
      'Monday · 8:00 PM',
      Color(0xFF9A69C7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.length - _read.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryDark),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(
                  () => _read.addAll(
                    List.generate(_notifications.length, (index) => index),
                  ),
                );
              },
              child: const Text(
                'Read all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          if (_notifications.isEmpty)
            const Center(child: Text('You’re all caught up'))
          else
            for (var index = 0; index < _notifications.length; index++)
              _notificationCard(index),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'You’re all caught up',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(int index) {
    final notification = _notifications[index];
    final isRead = _read.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isRead ? Colors.white : const Color(0xFFF4FAFA),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _read.add(index));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notification.$5.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    notification.$1,
                    color: notification.$5,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.$2,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.$3,
                        style: const TextStyle(
                          color: AppColors.secondaryDark,
                          height: 1.4,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.$4,
                        style: const TextStyle(
                          color: AppColors.secondaryDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
