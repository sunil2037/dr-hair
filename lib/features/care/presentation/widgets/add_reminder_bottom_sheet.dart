import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/care_cubit.dart';

/// Reusable bottom sheet for creating custom medicine and topical treatment reminders.
class AddReminderBottomSheet extends StatefulWidget {
  const AddReminderBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const AddReminderBottomSheet(),
    );
  }

  @override
  State<AddReminderBottomSheet> createState() => _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends State<AddReminderBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);
  String _frequency = 'Daily';

  @override
  void dispose() {
    _titleController.dispose();
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
              'Create Custom Reminder',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                ActionChip(
                  avatar: const Icon(LucideIcons.clock, size: 14),
                  label: Text(_selectedTime.format(context)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
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
                      selected: _frequency == f,
                      onSelected: (val) {
                        if (val) setState(() => _frequency = f);
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
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;

                  context.read<CareCubit>().addReminder(
                    title: title,
                    subtitle:
                        '$_frequency · ${_selectedTime.format(context)}',
                    time: _selectedTime,
                    frequency: _frequency,
                  );

                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
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
    );
  }
}
