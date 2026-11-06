import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';

class _ReminderPreset {
  final String title;
  final String treatmentType;
  final TimeOfDay time;
  final List<int> repeatDays;
  final String notes;
  final IconData icon;

  const _ReminderPreset({
    required this.title,
    required this.treatmentType,
    required this.time,
    required this.repeatDays,
    required this.notes,
    required this.icon,
  });
}

/// Reusable bottom sheet for creating or editing hair care regimen reminders
/// with active clinical presets, responsive timing, and direct backend API synchronization.
class AddReminderBottomSheet extends StatefulWidget {
  final CareReminder? reminderToEdit;

  const AddReminderBottomSheet({super.key, this.reminderToEdit});

  static Future<void> show(
    BuildContext context, {
    CareReminder? reminderToEdit,
  }) {
    final careCubit = context.read<CareCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider<CareCubit>.value(
        value: careCubit,
        child: AddReminderBottomSheet(reminderToEdit: reminderToEdit),
      ),
    );
  }

  @override
  State<AddReminderBottomSheet> createState() => _AddReminderBottomSheetState();
}

class _AddReminderBottomSheetState extends State<AddReminderBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final FocusNode _titleFocus;
  late TimeOfDay _selectedTime;
  late String _treatmentType;
  late List<int> _selectedDays;
  late bool _isEnabled;
  String? _titleError;
  bool _isSaving = false;
  bool _isDeleting = false;

  static const List<_ReminderPreset> _clinicalPresets = [
    _ReminderPreset(
      title: 'Dr. Hair 5% Minoxidil Booster',
      treatmentType: 'Topical Serum',
      time: TimeOfDay(hour: 22, minute: 0),
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      notes: 'Apply 1ml with dropper evenly on affected areas before bed',
      icon: LucideIcons.droplet,
    ),
    _ReminderPreset(
      title: 'Biotin & DHT Blocker Complex',
      treatmentType: 'Oral Supplement',
      time: TimeOfDay(hour: 9, minute: 0),
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      notes: '1 tablet after breakfast with a full glass of water',
      icon: LucideIcons.pill,
    ),
    _ReminderPreset(
      title: 'Ketoconazole 2% Scalp Wash',
      treatmentType: 'Medicated Wash',
      time: TimeOfDay(hour: 10, minute: 0),
      repeatDays: [3, 7],
      notes: 'Lather into wet scalp, leave on 5 mins, then rinse thoroughly',
      icon: LucideIcons.waves,
    ),
    _ReminderPreset(
      title: 'Scalp Dermaroller & Massage',
      treatmentType: 'Scalp Massage',
      time: TimeOfDay(hour: 21, minute: 30),
      repeatDays: [1, 3, 5],
      notes: '0.5mm dermaroller or 5 minutes circular fingertip massage',
      icon: LucideIcons.sparkles,
    ),
    _ReminderPreset(
      title: 'Monthly Scalp Progress Photo',
      treatmentType: 'Photo Check-in',
      time: TimeOfDay(hour: 11, minute: 0),
      repeatDays: [1],
      notes: 'Capture front hairline, crown, and top under consistent lighting',
      icon: LucideIcons.camera,
    ),
  ];

  static const List<Map<String, dynamic>> _treatmentTypeMeta = [
    {
      'name': 'Topical Serum',
      'icon': LucideIcons.droplets,
      'color': Color(0xFF1E3A8A),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'name': 'Oral Supplement',
      'icon': LucideIcons.pill,
      'color': Color(0xFF059669),
      'bg': Color(0xFFECFDF5),
    },
    {
      'name': 'Medicated Wash',
      'icon': LucideIcons.waves,
      'color': Color(0xFF0284C7),
      'bg': Color(0xFFF0F9FF),
    },
    {
      'name': 'Scalp Massage',
      'icon': LucideIcons.sparkles,
      'color': Color(0xFFEA580C),
      'bg': Color(0xFFFFF7ED),
    },
    {
      'name': 'Photo Check-in',
      'icon': LucideIcons.camera,
      'color': Color(0xFF7C3AED),
      'bg': Color(0xFFF5F3FF),
    },
    {
      'name': 'Custom Care',
      'icon': LucideIcons.calendarCheck2,
      'color': Color(0xFF4B5563),
      'bg': Color(0xFFF3F4F6),
    },
  ];

  static const List<Map<String, dynamic>> _quickTimeSlots = [
    {'label': 'Morning', 'time': TimeOfDay(hour: 8, minute: 0), 'icon': LucideIcons.sun},
    {'label': 'Afternoon', 'time': TimeOfDay(hour: 13, minute: 0), 'icon': LucideIcons.sunMedium},
    {'label': 'Evening', 'time': TimeOfDay(hour: 18, minute: 30), 'icon': LucideIcons.sunset},
    {'label': 'Night', 'time': TimeOfDay(hour: 22, minute: 0), 'icon': LucideIcons.moon},
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
    _titleFocus = FocusNode();
    _selectedTime = rem?.time ?? const TimeOfDay(hour: 20, minute: 0);
    _treatmentType = rem?.treatmentType ?? 'Topical Serum';
    _selectedDays = rem != null
        ? List<int>.from(rem.repeatDays)
        : [1, 2, 3, 4, 5, 6, 7];
    _isEnabled = rem?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.reminderToEdit != null;

  void _applyPreset(_ReminderPreset preset) {
    HapticFeedback.lightImpact();
    setState(() {
      _titleController.text = preset.title;
      _treatmentType = preset.treatmentType;
      _selectedTime = preset.time;
      _selectedDays = List<int>.from(preset.repeatDays);
      _notesController.text = preset.notes;
      _titleError = null;
    });
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        } else {
          AppToast.show(
            context,
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

  String _selectedDaysSummary() {
    if (_selectedDays.length == 7) return 'Daily';
    final sorted = List<int>.from(_selectedDays)..sort();
    if (sorted.length == 5 && sorted.every((d) => d <= 5)) {
      return 'Weekdays';
    }
    if (sorted.length == 2 && sorted.every((d) => d >= 6)) {
      return 'Weekends';
    }
    return sorted.map((d) => _dayLabels[d]).join(', ');
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _titleError = 'Please enter a reminder title');
      _titleFocus.requestFocus();
      return;
    }

    if (_selectedDays.isEmpty) {
      AppToast.show(
        context,
        const SnackBar(
          content: Text('Please select at least one day for reminder.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final frequency = _selectedDays.length == 7
        ? 'Daily'
        : (_selectedDays.length == 5 && _selectedDays.every((d) => d <= 5)
            ? 'Weekdays'
            : 'Custom');

    final reminder = CareReminder(
      id: widget.reminderToEdit?.id ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: '$_treatmentType · ${_selectedDaysSummary()}',
      time: _selectedTime,
      frequency: frequency,
      treatmentType: _treatmentType,
      repeatDays: _selectedDays,
      isEnabled: _isEnabled,
      notes: _notesController.text.trim(),
    );

    try {
      final auth = context.read<AuthCubit?>()?.state;
      final token = auth?.sessionToken;

      await context.read<CareCubit>().saveReminder(reminder, sessionToken: token);

      if (mounted) {
        AppToast.show(
          context,
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Care reminder updated successfully!'
                  : 'Care reminder scheduled successfully!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          const SnackBar(
            content: Text('Reminder saved to local care schedule.'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final reminder = widget.reminderToEdit;
    if (reminder == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Delete this reminder?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '“${reminder.title}” will be removed from your care schedule and alerts will stop.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep reminder'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Delete reminder'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = context.read<AuthCubit?>()?.state;
      final token = auth?.sessionToken;

      await context.read<CareCubit>().deleteReminder(reminder.id, sessionToken: token);

      if (mounted) {
        AppToast.show(
          context,
          const SnackBar(
            content: Text('Care reminder deleted.'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final viewHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: viewHeight * 0.90),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary5,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.bellRing,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Edit Care Reminder' : 'Add Care Reminder',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  if (_isEditing)
                    IconButton(
                      tooltip: 'Delete reminder',
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              LucideIcons.trash2,
                              color: AppColors.danger,
                              size: 20,
                            ),
                      onPressed: _isDeleting ? null : _confirmDelete,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Quick Presets Section (for new reminders)
                    if (!_isEditing) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Quick Clinical Suggestions',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _clinicalPresets.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final preset = _clinicalPresets[index];
                            return ActionChip(
                              avatar: Icon(preset.icon, size: 14, color: AppColors.primary),
                              label: Text(
                                preset.title.length > 24
                                    ? '${preset.title.substring(0, 22)}...'
                                    : preset.title,
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                              backgroundColor: AppColors.primary5,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onPressed: () => _applyPreset(preset),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Title Field
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Reminder Title',
                        hintText: 'e.g. Dr. Hair 5% Minoxidil Booster',
                        errorText: _titleError,
                        prefixIcon: const Icon(LucideIcons.tag, size: 18),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Treatment Category Chips
                    const Text(
                      'Treatment / Regimen Category',
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
                      children: _treatmentTypeMeta.map((meta) {
                        final type = meta['name'] as String;
                        final icon = meta['icon'] as IconData;
                        final isSelected = _treatmentType == type;
                        return ChoiceChip(
                          avatar: Icon(
                            icon,
                            size: 14,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppColors.primary5,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _treatmentType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 4. Scheduled Time with Quick Time Slots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scheduled Time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
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
                          child: const Text(
                            'Pick custom time',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  LucideIcons.chevronDown,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _quickTimeSlots.map((slot) {
                                final time = slot['time'] as TimeOfDay;
                                final label = slot['label'] as String;
                                final isPicked = _selectedTime.hour == time.hour &&
                                    _selectedTime.minute == time.minute;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(label),
                                    selected: isPicked,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isPicked ? FontWeight.w700 : FontWeight.w500,
                                      color: isPicked ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    selectedColor: AppColors.primary5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isPicked ? AppColors.primary : AppColors.border,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedTime = time);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 5. Repeat Days
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
                            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                            GestureDetector(
                              onTap: () => _setPresetDays([1, 3, 5]),
                              child: const Text(
                                'Alt Days',
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
                          label:
                              '${_fullDayLabels[dayNumber]}, ${isSelected ? "selected" : "not selected"}',
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

                    // 6. Notes Field
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Optional Dosage / Application Notes',
                        hintText: 'e.g. 1ml onto clean dry scalp before bed',
                        prefixIcon: const Icon(LucideIcons.notepadText, size: 18),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 7. Active Notification Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isEnabled ? LucideIcons.bell : LucideIcons.bellOff,
                                size: 18,
                                color: _isEnabled ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Reminder Alert',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  Text(
                                    _isEnabled
                                        ? 'Notification alarm scheduled'
                                        : 'Reminder is paused',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _isEnabled,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _isEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fixed Save button with Loading State
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: _isEditing ? 'Update Reminder' : 'Save Reminder',
                  variant: AppButtonVariant.filled,
                  size: AppButtonSize.large,
                  isLoading: _isSaving,
                  icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                  onPressed: _isSaving ? null : _saveReminder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
