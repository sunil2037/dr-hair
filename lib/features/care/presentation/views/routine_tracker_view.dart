import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/add_routine_task_bottom_sheet.dart';
import '../widgets/care_widgets.dart';

/// 1. Routine Tracker View
/// Allows users to view today's regimen progress, maintain daily streaks, and mark treatment steps done.
class RoutineTrackerView extends StatelessWidget {
  const RoutineTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final progress = state.routineProgress;
        final isAllCompleted = progress >= 1.0 && state.routineTasks.isNotEmpty;
        final today = DateTime.now();
        final weekStart = today.subtract(Duration(days: today.weekday - 1));

        return CarePageScaffold(
          title: 'Daily Routine',
          actions: [
            IconButton(
              tooltip: 'Reset daily steps',
              icon: const Icon(
                LucideIcons.rotateCcw,
                color: AppColors.primary,
                size: 18,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<CareCubit>().resetTodayRoutine();
              },
            ),
            IconButton(
              tooltip: 'Add new task',
              icon: const Icon(
                LucideIcons.plus,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => AddRoutineTaskBottomSheet.show(context),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Progress & Streak Card
              careCard(
                backgroundColor: isAllCompleted
                    ? const Color(0xFFECFDF5)
                    : Colors.white,
                border: Border.all(
                  color: isAllCompleted
                      ? const Color(0xFF10B981)
                      : AppColors.border,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAllCompleted
                                  ? '🎉 Daily Regimen Complete!'
                                  : 'Today’s Care Progress',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.completedRoutineCount} of ${state.routineTasks.length} steps complete',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${state.routineStreakDays} Days',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) =>
                            LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(8),
                              value: value,
                              minHeight: 8,
                              backgroundColor: AppColors.primary5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAllCompleted
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Weekly check-in dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .asMap()
                          .entries
                          .map((entry) {
                            final idx = entry.key;
                            final label = entry.value;
                            final date = weekStart.add(Duration(days: idx));
                            final dayKey =
                                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            final isPassed = state.routineCompletionDays
                                .contains(dayKey);
                            final isToday = date.weekday == today.weekday;
                            return Column(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isToday
                                        ? AppColors.primary
                                        : (isPassed
                                              ? const Color(0xFF10B981)
                                              : AppColors.background),
                                    border: Border.all(
                                      color: isToday
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isToday
                                          ? (isAllCompleted
                                                ? LucideIcons.check
                                                : LucideIcons.clock)
                                          : (isPassed
                                                ? LucideIcons.check
                                                : LucideIcons.circle),
                                      size: 14,
                                      color: isPassed || isToday
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.push(RouteNames.reminders),
                      icon: const Icon(LucideIcons.bell, size: 16),
                      label: const Text('Set a reminder'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.push(RouteNames.progress),
                      icon: const Icon(LucideIcons.camera, size: 16),
                      label: const Text('View progress journal'),
                    ),
                  ),
                ],
              ),

              careSectionHeader(
                title: 'TODAY’S CARE STEPS',
                subtitle: 'Tap an item when you complete that step today',
              ),

              // Interactive Routine Steps List
              ...state.routineTasks.map((task) {
                final isDone = task.isCompleted;

                Color tagBg;
                Color tagColor;
                if (task.category.contains('Topical')) {
                  tagBg = AppColors.primary5;
                  tagColor = AppColors.primary;
                } else if (task.category.contains('Supplement')) {
                  tagBg = const Color(0xFFECFDF5);
                  tagColor = const Color(0xFF059669);
                } else {
                  tagBg = const Color(0xFFFFF7ED);
                  tagColor = const Color(0xFFEA580C);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : AppColors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDone
                            ? Colors.transparent
                            : AppColors.primary.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CareCubit>().toggleRoutineTask(task.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : Colors.white,
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tagBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        task.category,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: tagColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '· ${task.timeOfDay}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDone
                                        ? AppColors.textSecondary
                                        : AppColors.primaryDark,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  task.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryDark,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => AddRoutineTaskBottomSheet.show(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Another Care Step'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
