import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_destination.dart';
import '../../data/models/notification_item_model.dart';
import '../viewmodels/notifications_cubit.dart';
import '../viewmodels/notifications_state.dart';

class NotificationsView extends StatelessWidget {
  final NotificationsCubit? cubit;

  const NotificationsView({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<NotificationsCubit>.value(
        value: cubit!,
        child: const _NotificationsContent(),
      );
    }
    return BlocProvider<NotificationsCubit>(
      create: (_) => NotificationsCubit()..loadNotifications(),
      child: const _NotificationsContent(),
    );
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent();

  static final List<NotificationItemModel> _skeletonItems = List.generate(
    3,
    (index) => NotificationItemModel(
      id: 'skeleton-$index',
      title: 'Your order is being processed for delivery',
      body: 'Your personalized scalp treatment formulation is being packaged at the Dr. Hair clinic.',
      type: 'order',
      destination: const AppDestination.screen('orders'),
      createdAt: DateTime.now(),
      isRead: false,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final notifications = state.isLoading && state.notifications.isEmpty
            ? _skeletonItems
            : state.notifications;

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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.primaryDark,
              ),
            ),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<NotificationsCubit>().markAllAsRead();
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
          body: Skeletonizer(
            enabled: state.isLoading && state.notifications.isEmpty,
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationsCubit>().loadNotifications(),
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  if (!state.isLoading && notifications.isEmpty)
                    _buildEmptyState(context)
                  else ...[
                    for (final item in notifications)
                      _notificationCard(context, item),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'You’re all caught up',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bellOff,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Appointment updates, order tracking, and doctor care tips will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context,
    NotificationItemModel notification,
  ) {
    final isRead = notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isRead ? Colors.white : const Color(0xFFF4FAFA),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<NotificationsCubit>().markAsRead(notification.id);

            // Dynamic deep link routing
            final targetLocation = notification.destination.location;
            if (targetLocation != null && targetLocation.isNotEmpty) {
              context.push(targetLocation);
            }
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
                    color: notification.iconColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    notification.iconData,
                    color: notification.iconColor,
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
                              notification.title,
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
                        notification.body,
                        style: const TextStyle(
                          color: AppColors.secondaryDark,
                          height: 1.4,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.formattedTime,
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
