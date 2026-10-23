import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
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
    return BlocProvider(
      create: (_) => HairTestCubit(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isSubmitted) {
          return _buildResultsView(context);
        }

        final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
        final Duration motionDuration = disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 260);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            centerTitle: true,
            title: const Text(
              'Clinical Hair Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () {
                if (state.currentStep > 0) {
                  context.read<HairTestCubit>().prevStep();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
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

                  // Navigation Buttons with Professional Hide/Show Motion
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
        final double targetBackWidth = (totalWidth - gap) / 3.0;

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
                    height: 54,
                    child: ClipRect(
                      child: Opacity(
                        opacity: backOpacity,
                        child: Transform.translate(
                          offset: Offset(slideOffset, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: targetBackWidth,
                              height: 54,
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
                    text: state.currentStep == state.totalSteps - 1
                        ? 'Submit Assessment'
                        : 'Continue',
                    variant: AppButtonVariant.filled,
                    size: AppButtonSize.large,
                    width: currentContinueWidth,
                    onPressed: () {
                      context.read<HairTestCubit>().nextStep();
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
          title: 'What is your biological gender?',
          subtitle: 'Hair loss pathways differ significantly between male and female androgen sensitivity.',
          options: const ['Male', 'Female'],
          selected: state.selectedGender,
          onSelected: (val) => cubit.selectGender(val),
        );
      case 1:
        return _buildOptionSelector(
          title: 'What is your primary hair concern?',
          subtitle:
              'Select the predominant symptom currently affecting your scalp.',
          options: const [
            'Receding Hairline (Temples)',
            'Crown Thinning',
            'Overall Density Loss',
            'Excessive Shedding & Dandruff',
          ],
          selected: state.primaryConcern,
          onSelected: (val) => cubit.selectPrimaryConcern(val),
        );
      case 2:
        return _buildOptionSelector(
          title: 'How long have you noticed hair fall?',
          subtitle: 'Helps determine whether follicles are resting (telogen) or miniaturized.',
          options: const [
            'Less than 6 months',
            '6 - 12 months',
            '1 - 3 years',
            'More than 3 years',
          ],
          selected: state.duration,
          onSelected: (val) => cubit.selectDuration(val),
        );
      case 3:
        return _buildOptionSelector(
          title: 'What is your average daily stress level?',
          subtitle: 'Cortisol elevation triggers vascular constriction around scalp capillaries.',
          options: const [
            'Low / Manageable',
            'Moderate',
            'High Stress',
            'Extreme',
          ],
          selected: state.stressLevel,
          onSelected: (val) => cubit.selectStressLevel(val),
        );
      case 4:
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
              'Our clinical dermatologists analyze your follicle density and hairline symmetry.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondaryDark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ...options.map((opt) {
          final isSelected = selected == opt;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => onSelected(opt),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
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
          );
        }),
      ],
    );
  }

  Widget _buildResultsView(BuildContext context) {
    final state = context.read<HairTestCubit>().state;
    final photoCount = state.photos.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Assessment Summary',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            context.read<HairTestCubit>().reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circleCheck,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assessment complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your personalized responses and scalp photos have been recorded for this care session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryDark,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card
              Container(
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
                      'ASSESSMENT PROFILE SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Primary Concern',
                      state.primaryConcern ?? 'Hair Fall & Thinning',
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildSummaryRow(
                      'Thinning Duration',
                      state.duration ?? '3 - 6 Months',
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildSummaryRow(
                      'Lifestyle Stress',
                      state.stressLevel ?? 'Moderate',
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildSummaryRow(
                      'Scalp Photos',
                      photoCount > 0
                          ? '$photoCount photos attached'
                          : 'No photos captured (optional)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Clinical Disclaimer & Honest State (Mandatory Requirement)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.stethoscope,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Algorithmic Assessment · Session Preview',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This assessment is generated algorithmically for care personalization and is not a certified doctor’s clinical diagnosis. Clinician triage services (POST /api/v1/assessment/submit) are pending live backend connection.',
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
              ),

              const SizedBox(height: 24),

              // Actions
              AppButton(
                text: 'Done',
                variant: AppButtonVariant.filled,
                size: AppButtonSize.large,
                width: double.infinity,
                onPressed: () {
                  context.read<HairTestCubit>().reset();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
