import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/hair_test_cubit.dart';
import '../viewmodels/hair_test_state.dart';
import 'hair_test_view.dart';

/// Standalone screen dedicated to viewing the Clinical Hair Assessment Result.
/// Accessible from Profile ("Assessment result") and direct navigation.
class AssessmentResultView extends StatelessWidget {
  final HairTestCubit? cubit;

  const AssessmentResultView({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _AssessmentResultContent(),
      );
    }
    final existingCubit = context.read<HairTestCubit?>();
    if (existingCubit != null) {
      return const _AssessmentResultContent();
    }
    return BlocProvider(
      create: (_) => HairTestCubit()..loadSavedState(),
      child: const _AssessmentResultContent(),
    );
  }
}

class _AssessmentResultContent extends StatefulWidget {
  const _AssessmentResultContent();

  @override
  State<_AssessmentResultContent> createState() =>
      _AssessmentResultContentState();
}

class _AssessmentResultContentState extends State<_AssessmentResultContent> {
  bool _previewSample = false;

  static const HairTestState _sampleReportState = HairTestState(
    isCompleted: true,
    name: 'Sahil',
    age: '23',
    stage: 'Stage 2 - Receding Hairline',
    dandruff: 'Severe Dandruff & Flakes',
    gutHealth: 'Occasional Gas & Acidity',
    stressLevel: 'Moderate Stress & Brain Fog',
    selectedGender: 'Male',
    duration: '6-12 Months',
    familyHistory: 'Maternal thinning',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HairTestCubit, HairTestState>(
      builder: (context, state) {
        final bool hasReport = state.isCompleted || state.isSubmitted;

        if (hasReport) {
          return AssessmentReportView(state: state);
        }

        if (_previewSample) {
          return AssessmentReportView(state: _sampleReportState);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.primaryDark,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(RouteNames.profile);
                }
              },
            ),
            title: const Text(
              'Assessment Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.primary5,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.clipboardCheck,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No Assessment Result Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete your 3-minute clinical hair analysis to view your personalized root cause diagnosis, stage assessment, and customized doctor regimen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryDark,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Take Hair Assessment',
                        variant: AppButtonVariant.filled,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        onPressed: () => context.push(RouteNames.hairTest),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Preview Sample Report',
                        variant: AppButtonVariant.outlined,
                        borderColor: AppColors.border,
                        foregroundColor: AppColors.primary,
                        onPressed: () {
                          setState(() {
                            _previewSample = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
