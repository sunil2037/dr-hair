import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';

// ============================================================================
// SHARED CARE SCAFFOLD & CARD COMPONENTS
// ============================================================================

class _CarePage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const _CarePage({
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: child,
        ),
      ),
    );
  }
}

Widget _card({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
  Color? backgroundColor,
  Border? border,
}) => Container(
  width: double.infinity,
  margin: margin,
  padding: padding,
  decoration: BoxDecoration(
    color: backgroundColor ?? Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: border ?? Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: child,
);

Widget _sectionHeader({required String title, String? subtitle}) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark),
        ),
      ],
    ],
  ),
);

// ============================================================================
// 1. ROUTINE TRACKER VIEW
// ============================================================================

class RoutineTrackerView extends StatelessWidget {
  const RoutineTrackerView({super.key});

  void _showAddCustomTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String category = 'Clinical Topical';
    String timeOfDay = 'Evening';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Routine Step',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add a personalized habit or medicine to your daily care regimen.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Care Step Title',
                    hintText: 'e.g. Scalp Dermarolling (0.5mm)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  decoration: InputDecoration(
                    labelText: 'Instructions / Dosage',
                    hintText: 'e.g. 5 minutes before applying serum',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                      ['Clinical Topical', 'Oral Supplement', 'Lifestyle']
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: category == c,
                              onSelected: (val) {
                                if (val) setSheetState(() => category = c);
                              },
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Time of Day',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Morning', 'Afternoon', 'Evening', 'Night']
                      .map(
                        (t) => ChoiceChip(
                          label: Text(t),
                          selected: timeOfDay == t,
                          onSelected: (val) {
                            if (val) setSheetState(() => timeOfDay = t);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Save Care Step',
                    variant: AppButtonVariant.filled,
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      context.read<CareCubit>().addCustomRoutineTask(
                        title: title,
                        subtitle: subtitleController.text.trim().isEmpty
                            ? 'As prescribed'
                            : subtitleController.text.trim(),
                        category: category,
                        timeOfDay: timeOfDay,
                      );
                      HapticFeedback.mediumImpact();
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Custom routine step added!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final progress = state.routineProgress;
        final isAllCompleted = progress >= 1.0 && state.routineTasks.isNotEmpty;

        return _CarePage(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Today’s routine steps reset.'),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Add new task',
              icon: const Icon(
                LucideIcons.plus,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => _showAddCustomTaskSheet(context),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Progress & Streak Card
              _card(
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.completedRoutineCount} of ${state.routineTasks.length} steps complete',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '🔥',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.routineStreakDays} Days',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) =>
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: AppColors.primary5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAllCompleted
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Weekly check-in dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final label = entry.value;
                        final isPassed = idx < 4; // demo days
                        final isToday = idx == 4;
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
                      }).toList(),
                    ),
                  ],
                ),
              ),

              _sectionHeader(
                title: 'TODAY’S CARE STEPS',
                subtitle: 'Tap each item as you complete your treatment',
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
                      width: isDone ? 1.5 : 1.0,
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
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
                                    size: 15,
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
                                    fontSize: 15,
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
                  onPressed: () => _showAddCustomTaskSheet(context),
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

// ============================================================================
// 2. PROGRESS TRACKING VIEW (WITH CUSTOM IMAGE PICKER)
// ============================================================================

class ProgressTrackingView extends StatelessWidget {
  const ProgressTrackingView({super.key});

  void _showAddPhotoSheet(BuildContext context) {
    String? localImagePath;
    String region = 'Crown / Vertex';
    String shedding = 'Low / Normal';
    int density = 4;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.88,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Log Hair Progress Check-in',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload consistent scalp photos to track follicle density changes.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Picker Trigger Box
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await PhotoSourceBottomSheet.show(
                        context,
                        title: 'Scalp Progress Photo',
                        subtitle:
                            'Capture a clear photo under bright, direct light',
                        cameraTitle: 'Open Camera',
                        cameraSubtitle:
                            'Snap a fresh scalp or hairline photo',
                        galleryTitle: 'Select from Gallery',
                        gallerySubtitle: 'Choose from your saved photos',
                        onSelectSource: (source) async {
                          try {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: source,
                              maxWidth: 1280,
                              maxHeight: 1280,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setSheetState(() => localImagePath = image.path);
                              HapticFeedback.lightImpact();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not access image: $e'),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: localImagePath != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: localImagePath != null ? 2 : 1,
                        ),
                      ),
                      child: localImagePath != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(localImagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          LucideIcons.camera,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Retake',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary5,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap to capture or upload photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Camera or photo gallery',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    'Target Scalp Region',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Crown / Vertex',
                      'Frontal Hairline',
                      'Temples',
                      'Overall Scalp',
                    ].map((r) => ChoiceChip(
                      label: Text(r),
                      selected: region == r,
                      onSelected: (val) {
                        if (val) setSheetState(() => region = r);
                      },
                    )).toList(),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Current Daily Shedding Level',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Low / Normal', 'Moderate', 'Noticeable', 'Heavy']
                        .map((s) => ChoiceChip(
                              label: Text(s),
                              selected: shedding == s,
                              onSelected: (val) {
                                if (val) setSheetState(() => shedding = s);
                              },
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Follicle Density Feel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (starIndex) {
                      final score = starIndex + 1;
                      return IconButton(
                        icon: Icon(
                          score <= density
                              ? LucideIcons.star
                              : LucideIcons.star,
                          color: score <= density
                              ? AppColors.starGold
                              : AppColors.border,
                          size: 26,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => density = score);
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Clinical Notes / Scalp Feel',
                      hintText:
                          'e.g. Less hair fall during combing, new baby hairs forming.',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Save Progress Photo',
                      variant: AppButtonVariant.filled,
                      onPressed: () {
                        final image = localImagePath ??
                            'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=600';

                        context.read<CareCubit>().addProgressCheckIn(
                          date: DateTime.now(),
                          imagePath: image,
                          scalpRegion: region,
                          sheddingLevel: shedding,
                          notes: notesController.text.trim().isEmpty
                              ? 'Logged regular monthly check-in photo.'
                              : notesController.text.trim(),
                          densityRating: density,
                        );

                        HapticFeedback.mediumImpact();
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Progress check-in logged! Clinical team notified.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCompareModal(BuildContext context, List<ProgressCheckIn> checkIns) {
    if (checkIns.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log at least 2 photos to compare before and after!'),
        ),
      );
      return;
    }

    final latest = checkIns.first;
    final baseline = checkIns.last;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Before & After Comparison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Comparing Day 1 Baseline vs Latest Scalp Photo',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildPhotoWidget(baseline.imagePath, height: 140),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Baseline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${baseline.date.day}/${baseline.date.month}/${baseline.date.year}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildPhotoWidget(latest.imagePath, height: 140),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                        Text(
                          '${latest.date.day}/${latest.date.month}/${latest.date.year}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Close Comparison',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPhotoWidget(String path, {double height = 180}) {
    if (path.startsWith('http')) {
      return CustomCachedImage(
        imageUrl: path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: height,
      color: AppColors.primary5,
      child: const Icon(LucideIcons.camera, color: AppColors.primary, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        return _CarePage(
          title: 'Hair Progress Journal',
          actions: [
            IconButton(
              tooltip: 'Compare before and after',
              icon: const Icon(
                LucideIcons.splitSquareVertical,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => _showCompareModal(context, state.checkIns),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(LucideIcons.camera, size: 18),
            label: const Text(
              'Add Check-In',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showAddPhotoSheet(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner Card
              _card(
                backgroundColor: AppColors.primary5,
                border: Border.all(color: AppColors.primary100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Hair Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Verified by Dr.Hair Dermatological Protocol',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatPill(
                          label: 'Total Check-ins',
                          value: '${state.checkIns.length} Photos',
                        ),
                        _buildStatPill(
                          label: 'Tracking Since',
                          value: state.checkIns.isNotEmpty
                              ? '${state.checkIns.last.date.month}/${state.checkIns.last.date.year}'
                              : 'Month 1',
                        ),
                        _buildStatPill(
                          label: 'Status',
                          value: 'Active Regrowth',
                          valueColor: const Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _showCompareModal(context, state.checkIns),
                            icon: const Icon(
                              LucideIcons.splitSquareVertical,
                              size: 16,
                            ),
                            label: const Text('Compare Before/After'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _sectionHeader(
                title: 'PHOTO TIMELINE',
                subtitle:
                    'Tap any photo to view full size or observe follicle density',
              ),

              if (state.checkIns.isEmpty)
                _card(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.camera,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No progress check-ins yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the button below to take your first scalp photo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...state.checkIns.map((ci) {
                  return _card(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with region tag & date & delete
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary5,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ci.scalpRegion,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${ci.date.day} ${_monthName(ci.date.month)} ${ci.date.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Check-in?'),
                                    content: const Text(
                                      'Are you sure you want to remove this progress photo from your journal?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context
                                              .read<CareCubit>()
                                              .deleteProgressCheckIn(ci.id);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Main Photo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            onTap: () {
                              // View Full screen photo modal
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        child: _buildPhotoWidget(
                                          ci.imagePath,
                                          height: 380,
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        top: 12,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(
                                              LucideIcons.x,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: _buildPhotoWidget(ci.imagePath, height: 180),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ratings & Shedding pill row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ci.sheddingLevel == 'Low / Normal'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.activity,
                                    size: 12,
                                    color: ci.sheddingLevel == 'Low / Normal'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFEA580C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Shedding: ${ci.sheddingLevel}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ci.sheddingLevel == 'Low / Normal'
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (s) => Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: s < ci.densityRating
                                      ? AppColors.starGold
                                      : AppColors.border,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (ci.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            ci.notes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryDark,
                              height: 1.4,
                            ),
                          ),
                        ],

                        if (ci.doctorNote != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary5,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.stethoscope,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ci.doctorNote!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStatPill({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[(month - 1).clamp(0, 11)];
  }
}

// ============================================================================
// 3. COACH BOOKING VIEW
// ============================================================================

class CoachBookingView extends StatefulWidget {
  const CoachBookingView({super.key});

  @override
  State<CoachBookingView> createState() => _CoachBookingViewState();
}

class _CoachBookingViewState extends State<CoachBookingView> {
  int _selectedCoachIndex = 0;
  int _selectedDateOffset = 1; // Tomorrow
  String _selectedSlot = '11:30 AM';
  String _consultationType = 'Video Consultation (15 mins)';
  final notesController = TextEditingController();

  final List<Map<String, String>> _coaches = [
    {
      'name': 'Dr. Priya Verma',
      'role': 'Senior Trichologist & MD',
      'exp': '8+ yrs exp',
      'avatar':
          'https://images.unsplash.com/photo-1594824813637-883a9e652a6a?q=80&w=300',
    },
    {
      'name': 'Aman Saxena',
      'role': 'Clinical Hair Health Coach',
      'exp': '5+ yrs exp',
      'avatar':
          'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=300',
    },
  ];

  final List<String> _slots = [
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
    '06:30 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        return _CarePage(
          title: 'Talk to a Hair Coach',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                backgroundColor: AppColors.primary5,
                border: Border.all(color: AppColors.primary100),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dedicated Trichology Guidance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review your ongoing treatment response, adjust topical dosages, or ask clinical diet questions with your Dr.Hair coach.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Scheduled Bookings (if any)
              if (state.coachBookings.isNotEmpty) ...[
                _sectionHeader(title: 'SCHEDULED CONSULTATIONS'),
                ...state.coachBookings.map((b) {
                  final isCancelled = b.status == 'Cancelled';
                  return _card(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CustomCachedImage(
                            imageUrl: b.avatarUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.coachName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${b.consultationType} · ${b.timeSlot}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCancelled
                                      ? AppColors.danger.withValues(alpha: 0.1)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  b.status,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCancelled
                                        ? AppColors.danger
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCancelled)
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            tooltip: 'Cancel booking',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.read<CareCubit>().cancelCoachBooking(b.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Consultation cancelled.'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],

              _sectionHeader(title: '1. SELECT YOUR SPECIALIST'),
              Row(
                children: _coaches.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final coach = entry.value;
                  final isSelected = _selectedCoachIndex == idx;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCoachIndex = idx);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: idx == 0 ? 10 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary5 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipOval(
                              child: CustomCachedImage(
                                imageUrl: coach['avatar']!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              coach['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              coach['exp']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              _sectionHeader(title: '2. CONSULTATION MODE'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.video, size: 15),
                          SizedBox(width: 6),
                          Text('Video Call (15m)'),
                        ],
                      ),
                      selected:
                          _consultationType == 'Video Consultation (15 mins)',
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => _consultationType =
                                'Video Consultation (15 mins)',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.phoneCall, size: 15),
                          SizedBox(width: 6),
                          Text('Phone Call (15m)'),
                        ],
                      ),
                      selected:
                          _consultationType == 'Phone Consultation (15 mins)',
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => _consultationType =
                                'Phone Consultation (15 mins)',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              _sectionHeader(title: '3. SELECT DATE & TIME'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(5, (i) {
                    final date = DateTime.now().add(Duration(days: i));
                    final isSelected = _selectedDateOffset == i;
                    final dayLabel = i == 0
                        ? 'Today'
                        : (i == 1 ? 'Tomorrow' : '${date.day} ${_monthName(date.month)}');

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDateOffset = i);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  final isSelected = _selectedSlot == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedSlot = s);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              _sectionHeader(title: '4. QUESTIONS / SYMPTOMS'),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Experiencing mild shedding, dosage question about topical serum.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Confirm Guidance Call',
                  variant: AppButtonVariant.filled,
                  onPressed: () {
                    final chosenDate =
                        DateTime.now().add(Duration(days: _selectedDateOffset));
                    final coach = _coaches[_selectedCoachIndex];

                    context.read<CareCubit>().bookCoach(
                      coachName: coach['name']!,
                      role: coach['role']!,
                      avatarUrl: coach['avatar']!,
                      date: chosenDate,
                      timeSlot: _selectedSlot,
                      consultationType: _consultationType,
                      notes: notesController.text.trim(),
                    );

                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                color: Color(0xFF059669),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Consultation Booked!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Appointment with ${coach['name']} on ${_monthName(chosenDate.month)} ${chosenDate.day} at $_selectedSlot.\nYou will receive a WhatsApp reminder 15 minutes before the call.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'Done',
                                variant: AppButtonVariant.filled,
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _monthName(int month) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[(month - 1).clamp(0, 11)];
  }
}

// ============================================================================
// 4. DIET & NUTRITION GUIDE VIEW
// ============================================================================

class DietPlanView extends StatelessWidget {
  const DietPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final currentDay = state.currentDietDay;
        final currentDayMeals = currentDay < state.dietPlans.length
            ? state.dietPlans[currentDay]
            : <DietMeal>[];

        return _CarePage(
          title: 'Nutrition & Diet Guide',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _card(
                backgroundColor: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🥗 Clinical Follicular Nutrition',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hair follicles are metabolically demanding tissues. Supplying adequate keratin building amino acids, biotin, and ferritin prevents telogen shedding.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7C2D12),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Water Intake Tracker
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F9FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.droplets,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hydration Intake',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${state.waterCups} of 8 glasses logged (~${(state.waterCups * 0.3).toStringAsFixed(1)}L)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.minusCircle),
                              color: AppColors.primary,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<CareCubit>().decrementWater();
                              },
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.plusCircle),
                              color: AppColors.primary,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<CareCubit>().incrementWater();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (state.waterCups / 8.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F9FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _sectionHeader(
                title: 'DAILY ROTATING MEAL PLAN',
                subtitle: 'Tap each meal once completed',
              ),

              // Day selector tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(state.dietPlans.length, (idx) {
                    final isSelected = currentDay == idx;
                    final titles = [
                      'Day 1: High Protein',
                      'Day 2: Zinc & Folate',
                      'Day 3: Iron & Omega-3',
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(titles[idx.clamp(0, titles.length - 1)]),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            context.read<CareCubit>().selectDietDay(idx);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // Meals list
              ...currentDayMeals.asMap().entries.map((entry) {
                final mealIdx = entry.key;
                final meal = entry.value;
                final isDone = meal.isCompleted;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : AppColors.border,
                      width: isDone ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context
                          .read<CareCubit>()
                          .toggleDietMeal(currentDay, mealIdx);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    meal.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      meal.nutrients,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                meal.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDone
                                      ? AppColors.textSecondary
                                      : AppColors.primaryDark,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal.benefit,
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
                );
              }),

              const SizedBox(height: 10),
              _sectionHeader(title: 'HAIR SUPERFOODS GLOSSARY'),
              _card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSuperfoodRow(
                      icon: '🫐',
                      title: 'Amla & Berries',
                      desc: 'Highest natural Vitamin C; drives scalp collagen.',
                    ),
                    const Divider(height: 20),
                    _buildSuperfoodRow(
                      icon: '🎃',
                      title: 'Pumpkin Seeds',
                      desc:
                          'Rich in phytosterols & zinc to suppress DHT naturally.',
                    ),
                    const Divider(height: 20),
                    _buildSuperfoodRow(
                      icon: '🥬',
                      title: 'Spinach & Methi',
                      desc: 'Bioavailable non-heme iron to lift ferritin levels.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildSuperfoodRow({
    required String icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. REMINDERS VIEW
// ============================================================================

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  void _showAddReminderSheet(BuildContext context) {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);
    String frequency = 'Daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Custom Reminder',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Reminder Title',
                    hintText: 'e.g. Scalp Clarifying Wash',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Time:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ActionChip(
                      avatar: const Icon(LucideIcons.clock, size: 14),
                      label: Text(selectedTime.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: ['Daily', 'Weekly', 'Monthly']
                      .map(
                        (f) => ChoiceChip(
                          label: Text(f),
                          selected: frequency == f,
                          onSelected: (val) {
                            if (val) setSheetState(() => frequency = f);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Save Reminder',
                    variant: AppButtonVariant.filled,
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      context.read<CareCubit>().addReminder(
                        title: title,
                        subtitle: '$frequency · ${selectedTime.format(context)}',
                        time: selectedTime,
                        frequency: frequency,
                      );

                      HapticFeedback.mediumImpact();
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Care reminder scheduled!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        return _CarePage(
          title: 'Care Reminders',
          actions: [
            IconButton(
              tooltip: 'Add reminder',
              icon: const Icon(
                LucideIcons.plus,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => _showAddReminderSheet(context),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
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

              _sectionHeader(
                title: 'ACTIVE REMINDERS',
                subtitle: 'Tap time chip to customize trigger schedule',
              ),

              ...state.reminders.map((rem) {
                final isEnabled = rem.isEnabled;
                return _card(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
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
                          size: 18,
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
                                fontSize: 14.5,
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
                                  context
                                      .read<CareCubit>()
                                      .updateReminderTime(rem.id, picked);
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
                                      size: 11,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rem.frequency} · ${rem.time.format(context)}',
                                      style: const TextStyle(
                                        fontSize: 11,
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
                      Switch(
                        value: isEnabled,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          context
                              .read<CareCubit>()
                              .toggleReminder(rem.id, val);
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

// ============================================================================
// 6. ORDER TRACKING VIEW
// ============================================================================

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final order = state.orders.isNotEmpty ? state.orders.first : null;

        return _CarePage(
          title: 'Orders & Deliveries',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order == null)
                _card(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.packageOpen,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No active orders found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Orders placed in the shop will appear here for live tracking.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Order Status Banner Card
                _card(
                  backgroundColor: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
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
                                'Order #${order.orderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                'Placed on ${order.orderDate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.truck,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Arrival: ${order.estimatedDelivery}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _sectionHeader(title: 'DISPATCH TIMELINE'),

                // Delivery Stepper
                _card(
                  child: Column(
                    children: [
                      _buildTimelineStep(
                        title: 'Order Confirmed & Payment Verified',
                        subtitle: 'Oct 20, 2026 · 10:14 AM',
                        isCompleted: order.currentStep >= 0,
                        isCurrent: order.currentStep == 0,
                      ),
                      _buildTimelineDivider(isCompleted: order.currentStep >= 1),
                      _buildTimelineStep(
                        title: 'Clinical Formulation Compounded',
                        subtitle: 'Pharmacist calibrated 5% topical booster',
                        isCompleted: order.currentStep >= 1,
                        isCurrent: order.currentStep == 1,
                      ),
                      _buildTimelineDivider(isCompleted: order.currentStep >= 2),
                      _buildTimelineStep(
                        title: 'Dispatched from Central Pharmacy',
                        subtitle: '${order.courierName} Hub · In transit',
                        isCompleted: order.currentStep >= 2,
                        isCurrent: order.currentStep == 2,
                      ),
                      _buildTimelineDivider(isCompleted: order.currentStep >= 3),
                      _buildTimelineStep(
                        title: 'Out for Delivery',
                        subtitle: 'Courier partner is on the way to your address',
                        isCompleted: order.currentStep >= 3,
                        isCurrent: order.currentStep == 3,
                      ),
                      _buildTimelineDivider(isCompleted: order.currentStep >= 4),
                      _buildTimelineStep(
                        title: 'Delivered',
                        subtitle: 'Expected by 2:00 PM',
                        isCompleted: order.currentStep >= 4,
                        isCurrent: order.currentStep == 4,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                _sectionHeader(title: 'SHIPPING & ITEMS'),

                // Courier & AWB Card
                _card(
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
                                order.courierName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'AWB: ${order.trackingNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.copy,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Copy Tracking ID',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: order.trackingNumber),
                              );
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tracking number copied to clipboard!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Delivery Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                // Order items breakdown
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items in this shipment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.package,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    it,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Support button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final uri = Uri.parse(
                        'https://wa.me/918058056789?text=Hi%20DrHair,%20I%20have%20an%20inquiry%20regarding%20my%20Order%20%23${order.orderId}',
                      );
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch WhatsApp: $e');
                      }
                    },
                    icon: Image.asset('assets/icons/whatsapp.png', height: 18),
                    label: const Text('Contact Support regarding this order'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isCurrent ? AppColors.primary : AppColors.border),
          ),
          child: Icon(
            isCompleted
                ? LucideIcons.check
                : (isCurrent ? LucideIcons.loader : LucideIcons.circle),
            size: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isCompleted || isCurrent
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildTimelineDivider({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 22,
      color: isCompleted ? const Color(0xFF10B981) : AppColors.border,
      alignment: Alignment.centerLeft,
    );
  }
}
