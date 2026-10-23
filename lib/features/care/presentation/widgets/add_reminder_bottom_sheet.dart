import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../../../../core/widgets/app_toast.dart';

/// Reusable bottom sheet for creating or editing hair care regimen reminders.
class AddReminderBottomSheet extends StatefulWidget {
  final CareReminder? reminderToEdit;

  const AddReminderBottomSheet({super.key, this.reminderToEdit});

  static Future<void> show(BuildContext context, {CareReminder? reminderToEdit}) {
    final careCubit = context.read<CareCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider<CareCubit>.value(
        value: careCubit,
        child: AddReminderBottomSheet(
          reminderToEdit: reminderToEdit,
        ),
      ),
    );
  }

  @override
  State<AddReminderBottomSheet> createState() => _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends State<AddReminderBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late TimeOfDay _selectedTime;
  late String _treatmentType;
  late List<int> _selectedDays;
  late bool _isEnabled;
  String? _titleError;

  static const List<String> _treatmentTypes = [
    'Topical Serum',
    'Oral Supplement',
    'Medicated Wash',
    'Scalp Massage',
    'Photo Check-in',
    'Custom Care',
  ];

  static const Map<int, String> _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  static const Map<int, String> _fullDayLabels = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    final rem = widget.reminderToEdit;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _notesController = TextEditingController(text: rem?.notes ?? '');
    _selectedTime = rem?.time ?? const TimeOfDay(hour: 20, minute: 0);
    _treatmentType = rem?.treatmentType ?? 'Topical Serum';
    _selectedDays = rem != null ? List<int>.from(rem.repeatDays) : [1, 2, 3, 4, 5, 6, 7];
    _isEnabled = rem?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.reminderToEdit != null;

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        } else {
          AppToast.show(context,
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              content: Text('At least one reminder day must remain selected.'),
            ),
          );
        }
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  void _setPresetDays(List<int> days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDays = List<int>.from(days)..sort();
    });
  }

  void _saveReminder() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a reminder title');
      return;
    }

    final cubit = context.read<CareCubit>();
    final frequency = _selectedDays.length == 7
        ? 'Daily'
        : (_selectedDays.length == 5 &&
                _selectedDays.every((d) => d >= 1 && d <= 5)
            ? 'Weekdays'
            : 'Custom');

    final reminder = CareReminder(
      id: widget.reminderToEdit?.id ??
          'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: '$_treatmentType · ${_selectedDaysSummary()}',
      time: _selectedTime,
      frequency: frequency,
      treatmentType: _treatmentType,
      repeatDays: _selectedDays,
      isEnabled: _isEnabled,
      notes: _notesController.text.trim(),
    );

    cubit.saveReminder(reminder);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    AppToast.show(context,
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text(
          _isEditing ? 'Reminder updated successfully.' : 'New reminder scheduled.',
        ),
      ),
    );
  }

  String _selectedDaysSummary() {
    if (_selectedDays.length == 7) return 'Daily';
    if (_selectedDays.length == 5 && _selectedDays.every((d) => d <= 5)) {
      return 'Weekdays';
    }
    if (_selectedDays.length == 2 && _selectedDays.every((d) => d >= 6)) {
      return 'Weekends';
    }
    return _selectedDays.map((d) => _dayLabels[d]).join(', ');
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text(
          'Are you sure you want to remove "${widget.reminderToEdit!.title}" from your care schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CareCubit>().deleteReminder(widget.reminderToEdit!.id);
              Navigator.pop(context);
              AppToast.show(context,
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Reminder deleted.'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Care Reminder' : 'Add Care Reminder',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      tooltip: 'Delete reminder',
                      icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 20),
                      onPressed: _confirmDelete,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      onChanged: (_) {
                        if (_titleError != null) setState(() => _titleError = null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Reminder Title',
                        hintText: 'e.g. 5% Minoxidil Booster',
                        errorText: _titleError,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Treatment Category
                    const Text(
                      'Treatment / Activity',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _treatmentTypes.map((type) {
                        final isSelected = _treatmentType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppColors.primary5,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _treatmentType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Scheduled Time
                    const Text(
                      'Scheduled Time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Repeat Days
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Repeat Days',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _setPresetDays([1, 2, 3, 4, 5, 6, 7]),
                              child: const Text(
                                'Everyday',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                            GestureDetector(
                              onTap: () => _setPresetDays([1, 2, 3, 4, 5]),
                              child: const Text(
                                'Weekdays',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayNumber = index + 1;
                        final isSelected = _selectedDays.contains(dayNumber);
                        return Semantics(
                          label: '${_fullDayLabels[dayNumber]}, ${isSelected ? "selected" : "not selected"}',
                          button: true,
                          child: InkWell(
                            onTap: () => _toggleDay(dayNumber),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _dayLabels[dayNumber]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Notes Field
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Optional Dosage / Application Notes',
                        hintText: 'e.g. 1ml onto dry scalp before bed',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Fixed non-scrollable Save button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _isEditing ? 'Update Reminder' : 'Save Reminder',
                  variant: AppButtonVariant.filled,
                  size: AppButtonSize.large,
                  onPressed: _saveReminder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
