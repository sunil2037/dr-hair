import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../viewmodels/hair_test_cubit.dart';
import '../viewmodels/hair_test_state.dart';

class HairTestView extends StatelessWidget {
  final HairTestCubit? cubit;

  const HairTestView({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: const _HairTestContent());
    }
    final existingCubit = context.read<HairTestCubit?>();
    if (existingCubit != null) {
      return const _HairTestContent();
    }
    return BlocProvider(
      create: (_) => HairTestCubit()..loadSavedState(),
      child: const _HairTestContent(),
    );
  }
}

class _HairTestContent extends StatelessWidget {
  const _HairTestContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HairTestCubit, HairTestState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.show(
            context,
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show report only once after the assessment is submitted in the current session
        final bool showAssessmentReport = state.isSubmitted;
        if (showAssessmentReport) {
          return AssessmentReportView(state: state);
        }

        final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
        final Duration motionDuration = disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 260);

        final bool isFirstStep = state.currentStep == 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Hair & Scalp Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: (!isFirstStep)
                ? IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () {
                      context.read<HairTestCubit>().prevStep();
                    },
                  )
                : null,
            actions: [
              TextButton(
                onPressed: () {
                  context.go(RouteNames.mainShell);
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar with Smooth Tween Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0 / state.totalSteps,
                      end: (state.currentStep + 1) / state.totalSteps,
                    ),
                    duration: motionDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, child) {
                      final int percent = (progress * 100)
                          .clamp(0, 100)
                          .toInt();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step ${state.currentStep + 1} of ${state.totalSteps}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '$percent% Complete',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(10),
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: AppColors.primary100,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Step Questions
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepContent(context, state),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Navigation Buttons with Smooth Hide/Show Motion
                  _buildNavigationButtons(
                    context: context,
                    state: state,
                    motionDuration: motionDuration,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons({
    required BuildContext context,
    required HairTestState state,
    required Duration motionDuration,
  }) {
    final bool showBack = state.currentStep > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        const double gap = 14.0;
        final double targetBackWidth = (totalWidth - gap) / 2.2;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: showBack ? 1.0 : 0.0),
          duration: motionDuration,
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            final double currentBackWidth = targetBackWidth * animValue;
            final double currentGap = gap * animValue;
            final double currentContinueWidth =
                totalWidth - currentBackWidth - currentGap;
            final double backOpacity = animValue.clamp(0.0, 1.0);
            final double slideOffset = -20.0 * (1.0 - animValue);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBack || animValue > 0.001) ...[
                  SizedBox(
                    width: currentBackWidth,
                    height: 50,
                    child: ClipRect(
                      child: Opacity(
                        opacity: backOpacity,
                        child: Transform.translate(
                          offset: Offset(slideOffset, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: targetBackWidth,
                              height: 50,
                              child: AppButton(
                                text: 'Back',
                                variant: AppButtonVariant.outlined,
                                size: AppButtonSize.large,
                                width: targetBackWidth,
                                height: 54,
                                onPressed: () {
                                  context.read<HairTestCubit>().prevStep();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: currentGap),
                ],
                SizedBox(
                  width: currentContinueWidth,
                  child: AppButton(
                    height: 50,
                    text: state.isSubmitting
                        ? 'Submitting…'
                        : state.currentStep == state.totalSteps - 1
                        ? 'Submit'
                        : 'Continue',
                    variant: AppButtonVariant.filled,
                    size: AppButtonSize.large,
                    width: currentContinueWidth,
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            final auth = context.read<AuthCubit?>()?.state;
                            unawaited(
                              context.read<HairTestCubit>().nextStep(
                                sessionToken: auth?.sessionToken,
                                patientName: auth?.user?.name,
                                patientAge: auth?.user?.age,
                              ),
                            );
                          },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, HairTestState state) {
    final cubit = context.read<HairTestCubit>();

    switch (state.currentStep) {
      case 0:
        return _buildOptionSelector(
          title: 'How do you describe your gender?',
          subtitle: 'This helps us make the screening questions more relevant.',
          options: const ['Male', 'Female', 'Prefer not to say'],
          selected: state.selectedGender,
          onSelected: (val) => cubit.selectGender(val),
        );
      case 1:
        return _buildHairPatternSelector(state, cubit);
      case 2:
        return _buildOptionSelector(
          title: 'How long have you noticed hair loss or thinning?',
          subtitle: 'Choose the closest timeframe.',
          options: const [
            'Less than 6 months',
            '6 - 12 months',
            '1 - 3 years',
            'More than 3 years',
          ],
          selected: state.duration,
          onSelected: cubit.selectDuration,
        );
      case 3:
        return _buildOptionSelector(
          title: 'How is your scalp feeling lately?',
          subtitle: 'Choose the closest description. You can discuss symptoms with a clinician.',
          options: const [
            'No noticeable flakes or itching',
            'Occasional flakes or itching',
            'Frequent flakes or itching',
            'Not sure',
          ],
          selected: state.dandruff,
          onSelected: cubit.selectDandruff,
        );
      case 4:
        return _buildOptionSelector(
          title: 'How would you describe your recent stress level?',
          subtitle: 'There are no right or wrong answers.',
          options: const [
            'Moderate',
            'Low / Manageable',
            'High Stress',
            'Extreme',
          ],
          selected: state.stressLevel,
          onSelected: cubit.selectStressLevel,
        );
      case 5:
        return _buildOptionSelector(
          title: 'Any digestion or gut-health concerns?',
          subtitle: 'Choose the option that best reflects your experience.',
          options: const ['No', 'Sometimes', 'Often', 'Not sure'],
          selected: state.gutHealth,
          onSelected: cubit.selectGutHealth,
        );
      case 6:
        return _buildOptionSelector(
          title: 'Is hair thinning common in your family?',
          subtitle: 'This is optional context for a future conversation with a clinician.',
          options: const ['Yes', 'No', 'Not sure'],
          selected: state.familyHistory,
          onSelected: cubit.selectFamilyHistory,
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Scalp Photos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Optional photos are separate from the illustrated choices. In this demo, they stay on this device as part of your assessment preview; they are not analyzed, sent to a clinician, or automatically reviewed.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoUploadBox(
                    context,
                    'Front Hairline',
                    LucideIcons.scanFace,
                    state,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPhotoUploadBox(
                    context,
                    'Crown / Top',
                    LucideIcons.scanSearch,
                    state,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildPhotoUploadBox(
              context,
              'Side Profile / Temples',
              LucideIcons.userRound,
              state,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                icon: const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Continue without photos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        final auth = context.read<AuthCubit?>()?.state;
                        unawaited(
                          cubit.skipPhotosAndSubmit(
                            sessionToken: auth?.sessionToken,
                            patientName: auth?.user?.name,
                            patientAge: auth?.user?.age,
                          ),
                        );
                      },
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhotoUploadBox(
    BuildContext context,
    String label,
    IconData icon,
    HairTestState state,
  ) {
    final String? photoPath = state.getPhoto(label);
    final bool hasPhoto = photoPath != null && photoPath.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPhotoSourceBottomSheet(context, label),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 154,
          decoration: BoxDecoration(
            color: hasPhoto ? Colors.black : AppColors.primary5,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasPhoto ? AppColors.primary : AppColors.primary100,
              width: hasPhoto ? 2 : 1.5,
            ),
            boxShadow: hasPhoto
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto) ...[
                  Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(icon, color: Colors.white70, size: 36),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Retake',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary100.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to upload photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoSourceBottomSheet(BuildContext context, String label) {
    final cubit = context.read<HairTestCubit>();
    final bool hasExistingPhoto = cubit.state.hasPhoto(label);

    PhotoSourceBottomSheet.show(
      context,
      title: 'Upload Photo',
      subtitle: 'Select image source for $label',
      cameraSubtitle: 'Open camera to capture your scalp',
      gallerySubtitle: 'Select an existing photo from library',
      removeSubtitle: 'Clear current photo for $label',
      hasExistingPhoto: hasExistingPhoto,
      onSelectSource: (source) => cubit.pickPhoto(label: label, source: source),
      onRemovePhoto: () => cubit.removePhoto(label),
    );
  }

  Widget _buildOptionSelector({
    required String title,
    required String subtitle,
    required List<String> options,
    required String? selected,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = selected == opt;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(opt),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 3 : 1.2,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHairPatternSelector(HairTestState state, HairTestCubit cubit) {
    const stages = <(String, String)>[
      ('Stage 1', 'assets/images/hair_assessment/stage_1.png'),
      ('Stage 2', 'assets/images/hair_assessment/stage_2.png'),
      ('Stage 3', 'assets/images/hair_assessment/stage_3.png'),
      ('Stage 4', 'assets/images/hair_assessment/stage_4.png'),
      ('Stage 5', 'assets/images/hair_assessment/stage_5.png'),
      ('Patchy hair loss', 'assets/images/hair_assessment/patchy_loss.png'),
      ('Hair shedding', 'assets/images/hair_assessment/hair_fall.png'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which image looks closest to what you have noticed?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the closest example. These illustrations are for guidance only and do not determine a diagnosis.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (label, imageAsset) in stages.take(5))
                      _buildHairPatternCard(
                        label: label,
                        imageAsset: imageAsset,
                        selected:
                            state.primaryConcern == label ||
                            state.stage == label,
                        width: cardWidth,
                        onTap: () => cubit.selectPrimaryConcern(label),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Other concerns',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (label, imageAsset) in stages.skip(5))
                      _buildHairPatternCard(
                        label: label,
                        imageAsset: imageAsset,
                        selected:
                            state.primaryConcern == label ||
                            state.stage == label,
                        width: cardWidth,
                        onTap: () => cubit.selectPrimaryConcern(label),
                      ),
                    _buildNotSureCard(
                      selected: state.primaryConcern == 'Not sure',
                      onTap: () => cubit.selectPrimaryConcern('Not sure'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHairPatternCard({
    required String label,
    required String imageAsset,
    required bool selected,
    required double width,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox(
        width: width,
        height: 142,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 84,
                    height: 78,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.primaryDark,
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

  Widget _buildNotSureCard({
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Not sure',
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary5 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? LucideIcons.circleCheck : LucideIcons.circleHelp,
                    size: 19,
                    color: selected
                        ? AppColors.primary
                        : AppColors.secondaryDark,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Not sure',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.primaryDark,
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
}

/// The Clinical Assessment Report View meticulously matching the user's uploaded screenshot.
class AssessmentReportView extends StatefulWidget {
  final HairTestState state;

  const AssessmentReportView({super.key, required this.state});

  @override
  State<AssessmentReportView> createState() => _AssessmentReportViewState();
}

class _AssessmentReportViewState extends State<AssessmentReportView> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedPattern = _selectedPatternIllustration(state);
    final String trimmedName = state.name.trim();
    final String displayName = trimmedName.isNotEmpty
        ? '${trimmedName[0].toUpperCase()}${trimmedName.substring(1)}, ${state.age}'
        : 'Patient, ${state.age}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primaryDark),
          onPressed: () {
            context.read<HairTestCubit>().dismissReport();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.mainShell);
            }
          },
        ),
        title: const Text(
          'Assessment Report',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<HairTestCubit>().startRetest();
              context.push(RouteNames.hairTest);
            },
            child: const Text(
              'Retest',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Diagnosis Card (White container with border)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            color: Color(0xFF1B6A47),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Self-assessment complete',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B6A47),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (selectedPattern != null) ...[
                      const SizedBox(height: 4),
                      _buildSelectedPatternCard(selectedPattern),
                      const SizedBox(height: 16),
                    ],

                    // Patient Header Row with Avatar (Responsive layout)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Your answers suggest',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                state.assessmentSummary,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LucideIcons.clipboardCheck,
                            color: AppColors.primary,
                            size: 25,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What this may mean',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.stageDescription,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSummaryCard(state),

              const SizedBox(height: 16),

              // Explain how to interpret this screening summary.
              _buildDisclaimerBox(),

              const SizedBox(height: 24),

              _buildPostAssessmentNextSteps(context),

              const SizedBox(height: 24),

              // Practical Actions (No Bottom Price Bar)
              AppButton(
                height: 50,
                text: 'Browse demo products',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                width: double.infinity,
                onPressed: () {
                  context.read<HairTestCubit>().dismissReport();
                  context.push(RouteNames.products);
                },
              ),

              const SizedBox(height: 12),

              AppButton(
                height: 50,
                text: 'Done',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                width: double.infinity,
                onPressed: () {
                  context.read<HairTestCubit>().dismissReport();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(RouteNames.mainShell);
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPatternCard(({String label, String asset}) pattern) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 86,
            child: Image.asset(
              pattern.asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your selected pattern',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pattern.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is the illustration you selected.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAssessmentNextSteps(BuildContext context) {
    final hairState = context.watch<HairTestCubit>().state;
    final hasCompletedAssessment =
        hairState.isCompleted && !hairState.isRetesting;

    if (!hasCompletedAssessment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Want your own care plan?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete your hair assessment to unlock your routine and progress tools.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              text: 'Start my assessment',
              variant: AppButtonVariant.filled,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.push(RouteNames.hairTest),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your next steps',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Build a simple care habit and track changes over time.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          _nextStepRow('1', 'Review your daily routine'),
          _nextStepRow('2', 'Set a reminder that works for you'),
          _nextStepRow('3', 'Add a baseline progress photo'),
          const SizedBox(height: 12),
          AppButton(
            text: 'Set up my routine',
            variant: AppButtonVariant.filled,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => context.push(RouteNames.routine),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.push(RouteNames.reminders),
                  child: const Text('Set a reminder'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      context.push(RouteNames.progress, extra: true),
                  child: const Text('Add progress photo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextStepRow(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary5,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(HairTestState state) {
    final photoCount = state.photos.length;
    final details = <MapEntry<String, String>>[];

    void addDetail(String label, String? value) {
      final trimmedValue = value?.trim();
      if (trimmedValue != null && trimmedValue.isNotEmpty) {
        details.add(MapEntry(label, trimmedValue));
      }
    }

    addDetail('Hair concern', state.primaryConcern ?? state.stage);
    addDetail('Duration', state.duration);
    addDetail('Scalp concern', state.dandruff);
    addDetail('Gut health', state.gutHealth);
    addDetail('Stress & lifestyle', state.stressLevel);
    addDetail('Family history', state.familyHistory);
    details.add(
      MapEntry(
        'Photos',
        photoCount > 0 ? '$photoCount added' : 'Not added · optional',
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT YOU SHARED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These are the details you selected for this assessment.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < details.length; index++) ...[
            if (index > 0) const Divider(height: 16, color: AppColors.border),
            _buildSummaryRow(details[index].key, details[index].value),
          ],
        ],
      ),
    );
  }

  Widget _buildDisclaimerBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.stethoscope, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use this result',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This summary is based on your answers and is not a medical diagnosis. A qualified clinician can assess your symptoms and discuss suitable care.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

({String label, String asset})? _selectedPatternIllustration(
  HairTestState state,
) {
  final selected = state.primaryConcern?.trim();
  final value = selected == null || selected.isEmpty
      ? state.stage?.trim()
      : selected;
  if (value == null || value.isEmpty || value == 'Not sure') return null;

  const stageAssets = <String, String>{
    'Stage 1': 'assets/images/hair_assessment/stage_1.png',
    'Stage 2': 'assets/images/hair_assessment/stage_2.png',
    'Stage 3': 'assets/images/hair_assessment/stage_3.png',
    'Stage 4': 'assets/images/hair_assessment/stage_4.png',
    'Stage 5': 'assets/images/hair_assessment/stage_5.png',
  };
  for (final entry in stageAssets.entries) {
    if (value == entry.key || value.startsWith('${entry.key} -')) {
      return (label: entry.key, asset: entry.value);
    }
  }

  final normalized = value.toLowerCase();
  if (normalized.contains('patch')) {
    return (
      label: 'Patchy hair loss',
      asset: 'assets/images/hair_assessment/patchy_loss.png',
    );
  }
  if (normalized.contains('shed') || normalized.contains('hair fall')) {
    return (
      label: 'Hair shedding',
      asset: 'assets/images/hair_assessment/hair_fall.png',
    );
  }
  return null;
}
