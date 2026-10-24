import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';
import 'app_button.dart';

/// Explains why personalized care features need an assessment first.
Future<void> showAssessmentRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
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
            Navigator.of(sheetContext).pop();
            context.push(RouteNames.hairTest);
          }),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Maybe later'))),
        ],
      ),
    ),
  );
}
