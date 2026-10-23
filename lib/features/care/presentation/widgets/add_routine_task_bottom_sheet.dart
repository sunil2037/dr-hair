import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/care_cubit.dart';

/// Reusable bottom sheet for creating a custom care routine task.
class AddRoutineTaskBottomSheet extends StatefulWidget {
  const AddRoutineTaskBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const AddRoutineTaskBottomSheet(),
    );
  }

  @override
  State<AddRoutineTaskBottomSheet> createState() =>
      _AddRoutineTaskBottomSheetState();
}

class _AddRoutineTaskBottomSheetState extends State<AddRoutineTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  String _category = 'Clinical Topical';
  String _timeOfDay = 'Evening';

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
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
              controller: _subtitleController,
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
              children: ['Clinical Topical', 'Oral Supplement', 'Lifestyle']
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (val) {
                        if (val) setState(() => _category = c);
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
                      selected: _timeOfDay == t,
                      onSelected: (val) {
                        if (val) setState(() => _timeOfDay = t);
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
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;
                  context.read<CareCubit>().addCustomRoutineTask(
                    title: title,
                    subtitle: _subtitleController.text.trim().isEmpty
                        ? 'As prescribed'
                        : _subtitleController.text.trim(),
                    category: _category,
                    timeOfDay: _timeOfDay,
                  );
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
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
    );
  }
}
