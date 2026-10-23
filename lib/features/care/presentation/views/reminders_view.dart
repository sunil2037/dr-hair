import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/add_reminder_bottom_sheet.dart';
import '../widgets/care_widgets.dart';

/// 5. Reminders View
/// Consistent topical serums & supplement reminder schedules with toggle switches and custom time pickers.
class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
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
                  children: [
                    Icon(
                      LucideIcons.bellRing,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Dose Consistency',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Timed notifications ensure consistent plasma levels of clinical active ingredients.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              careSectionHeader(
                title: 'ACTIVE REMINDERS',
                subtitle: 'Tap time chip to customize trigger schedule',
              ),

              ...state.reminders.map((rem) {
                final isEnabled = rem.isEnabled;
                return careCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? AppColors.primary5
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          rem.title.contains('Morning')
                              ? LucideIcons.sunMedium
                              : (rem.title.contains('Evening')
                                    ? LucideIcons.moon
                                    : LucideIcons.bell),
                          size: 20,
                          color: isEnabled
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rem.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isEnabled
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: rem.time,
                                );
                                if (picked != null && context.mounted) {
                                  HapticFeedback.selectionClick();
                                  context.read<CareCubit>().updateReminderTime(
                                    rem.id,
                                    picked,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.clock,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rem.frequency} · ${rem.time.format(context)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: isEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          context.read<CareCubit>().toggleReminder(rem.id, val);
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Test notification sent! "Dr.Hair: Evening topical serum ready."',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.bell, size: 16),
                  label: const Text('Send Test Push Notification'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
