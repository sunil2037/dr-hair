import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';
import 'app_button.dart';
import '../../features/hair_test/presentation/viewmodels/hair_test_cubit.dart';

/// Route-level guard so personalized screens cannot be opened through a deep
/// link or a Home action that forgot to check assessment state.
class AssessmentRequiredRoute extends StatefulWidget {
  final Widget child;

  const AssessmentRequiredRoute({super.key, required this.child});

  @override
  State<AssessmentRequiredRoute> createState() =>
      _AssessmentRequiredRouteState();
}

class _AssessmentRequiredRouteState extends State<AssessmentRequiredRoute> {
  bool _gateScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gateScheduled) return;
    _gateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final assessment = context.read<HairTestCubit?>()?.state;
      if (assessment != null && assessment.isCompleted && !assessment.isRetesting) {
        return;
      }
      await showAssessmentRequiredSheet(context);
      if (!mounted) return;
      final updatedAssessment = context.read<HairTestCubit?>()?.state;
      if (updatedAssessment != null &&
          updatedAssessment.isCompleted &&
          !updatedAssessment.isRetesting) {
        return;
      }
      if (context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessment = context.watch<HairTestCubit?>()?.state;
    final allowed = assessment != null &&
        assessment.isCompleted &&
        !assessment.isRetesting;
    if (allowed) return widget.child;
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.shrink(),
    );
  }
}

/// Explains why personalized care features need an assessment first.
Future<bool?> showAssessmentRequiredSheet(BuildContext context) {
  return _showAssessmentRequiredSheet(context);
}

Future<bool?> _showAssessmentRequiredSheet(BuildContext context) async {
  final startAssessment = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Start with your hair assessment', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          const Text('Complete the assessment to unlock your personalized treatment plan, daily routine, and progress tracking.', style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.secondaryDark)),
          const SizedBox(height: 20),
          AppButton(text: 'Start assessment', variant: AppButtonVariant.filled, backgroundColor: AppColors.primary, foregroundColor: Colors.white, onPressed: () {
            Navigator.of(sheetContext).pop(true);
          }),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(false), child: const Text('Maybe later'))),
        ],
      ),
    ),
  );
  if (startAssessment == true && context.mounted) {
    await context.push(RouteNames.hairTest);
  }
  return startAssessment;
}
