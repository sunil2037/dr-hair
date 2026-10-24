import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/add_reminder_bottom_sheet.dart';
import '../widgets/care_widgets.dart';
import '../../../../core/widgets/app_toast.dart';

/// Reminders View
/// Comprehensive hair care regimen reminder manager with custom repeat days,
/// snooze capabilities, completion tracking, permission recovery, and local persistence.
class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  void _showSnoozeOptions(BuildContext context, CareReminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Snooze "${reminder.title}"',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose when you would like to be reminded again:',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.alarmClock, color: AppColors.primary),
                title: const Text('15 Minutes'),
                onTap: () {
                  context.read<CareCubit>().snoozeReminder(
                        reminder.id,
                        duration: const Duration(minutes: 15),
                      );
                  Navigator.pop(sheetContext);
                  AppToast.show(context,
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Snooze preview set for 15 minutes. No alert will be sent in this demo.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.clock, color: AppColors.primary),
                title: const Text('1 Hour'),
                onTap: () {
                  context.read<CareCubit>().snoozeReminder(
                        reminder.id,
                        duration: const Duration(hours: 1),
                      );
                  Navigator.pop(sheetContext);
                  AppToast.show(context,
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Snooze preview set for 1 hour. No alert will be sent in this demo.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.moon, color: AppColors.primary),
                title: const Text('Tonight (8:00 PM)'),
                onTap: () {
                  final now = DateTime.now();
                  final tonight = DateTime(now.year, now.month, now.day, 20);
                  final duration = tonight.isAfter(now)
                      ? tonight.difference(now)
                      : const Duration(hours: 3);
                  context.read<CareCubit>().snoozeReminder(reminder.id, duration: duration);
                  Navigator.pop(sheetContext);
                  AppToast.show(context,
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Snooze preview set for 8:00 PM. No alert will be sent in this demo.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForReminder(CareReminder reminder) {
    final type = reminder.treatmentType.toLowerCase();
    final title = reminder.title.toLowerCase();
    if (type.contains('oral') || title.contains('supplement') || title.contains('tablet') || title.contains('biotin')) {
      return LucideIcons.pill;
    }
    if (type.contains('wash') || title.contains('wash') || title.contains('shampoo') || title.contains('cleanser')) {
      return LucideIcons.sparkles;
    }
    if (type.contains('photo') || title.contains('photo') || title.contains('check-in')) {
      return LucideIcons.camera;
    }
    if (type.contains('massage') || title.contains('massage')) {
      return LucideIcons.hand;
    }
    if (title.contains('morning')) return LucideIcons.sunMedium;
    if (title.contains('evening') || title.contains('night')) return LucideIcons.moon;
    return LucideIcons.droplets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final reminders = state.reminders;

        return CarePageScaffold(
          title: 'Care Reminders',
          actions: [
            IconButton(
              tooltip: 'Add reminder',
              icon: const Icon(
                LucideIcons.plus,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => AddReminderBottomSheet.show(context),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              careCard(
                backgroundColor: AppColors.primary5,
                border: Border.all(color: AppColors.primary100),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.bellRing, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder demo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Schedules are saved on this device for the demo. This version does not send push notifications or trigger timed alerts.',
                            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.secondaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Section Header
              careSectionHeader(
                title: 'SCHEDULED REMINDERS',
                subtitle: 'Tap any reminder to edit schedule, days, or notes',
              ),

              if (reminders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primary5,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.calendarClock, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Care Reminders Scheduled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add daily or weekly alerts for topicals and supplements to keep your treatment on track.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Add First Reminder',
                        variant: AppButtonVariant.filled,
                        onPressed: () => AddReminderBottomSheet.show(context),
                      ),
                    ],
                  ),
                )
              else
                ...reminders.map((rem) {
                  final isEnabled = rem.isEnabled;
                  final isCompleted = rem.isCompleted;
                  final isSnoozed = rem.isSnoozed;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.background
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.border
                            : (isEnabled ? AppColors.primary100 : AppColors.border),
                      ),
                      boxShadow: [
                        if (!isCompleted && isEnabled)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => AddReminderBottomSheet.show(context, reminderToEdit: rem),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Leading Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? AppColors.primary5
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _iconForReminder(rem),
                                    size: 20,
                                    color: isEnabled ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title and Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              rem.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                decoration: isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: isCompleted
                                                    ? AppColors.textMuted
                                                    : (isEnabled
                                                        ? AppColors.primaryDark
                                                        : AppColors.textSecondary),
                                              ),
                                            ),
                                          ),
                                          if (isSnoozed)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Snoozed',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${rem.treatmentType} · ${rem.daysSummary}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Toggle Switch
                                Semantics(
                                  label: 'Toggle ${rem.title} reminder',
                                  child: CupertinoSwitch(
                                    value: isEnabled,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (val) {
                                      HapticFeedback.lightImpact();
                                      context.read<CareCubit>().toggleReminder(rem.id, val);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 8),

                            // Bottom actions row: Time chip, Notes, Snooze, Done
                            Row(
                              children: [
                                // Time Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.clock, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        rem.timeFormatted,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (rem.notes.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      rem.notes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ] else
                                  const Spacer(),

                                // Snooze Button
                                if (isEnabled && !isCompleted)
                                  IconButton(
                                    tooltip: 'Snooze reminder',
                                    icon: const Icon(LucideIcons.alarmClock, size: 16, color: AppColors.secondaryDark),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showSnoozeOptions(context, rem),
                                  ),

                                // Done / Undone check action
                                Semantics(
                                  label: isCompleted
                                      ? 'Mark ${rem.title} not done'
                                      : 'Mark ${rem.title} done today',
                                  button: true,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      context.read<CareCubit>().toggleReminderCompletion(rem.id);
                                    },
                                    icon: Icon(
                                      isCompleted
                                          ? LucideIcons.circleCheck
                                          : LucideIcons.circle,
                                      size: 15,
                                      color: isCompleted ? AppColors.success : AppColors.textMuted,
                                    ),
                                    label: Text(
                                      isCompleted ? 'Done' : 'Mark Done',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isCompleted ? AppColors.success : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Test Push Preview action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                  },
                  icon: const Icon(LucideIcons.bell, size: 16),
                  label: const Text('Send Test Push Notification'),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Local notifications simulated · Native setup: Android POST_NOTIFICATIONS, iOS UNUserNotificationCenter',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
