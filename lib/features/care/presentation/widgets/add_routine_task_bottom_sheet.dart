import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../viewmodels/care_cubit.dart';

class _RoutinePreset {
  final String title;
  final String subtitle;
  final String category;
  final String timeOfDay;
  final IconData icon;

  const _RoutinePreset({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timeOfDay,
    required this.icon,
  });
}

/// Reusable, clinically-oriented bottom sheet for adding a custom care routine task.
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
  final FocusNode _titleFocus = FocusNode();

  String _category = 'Clinical Topical';
  String _timeOfDay = 'Night';
  bool _isSaving = false;

  static const List<_RoutinePreset> _presets = [
    _RoutinePreset(
      title: 'Minoxidil 5% Solution',
      subtitle: 'Apply 1ml with dropper to affected scalp areas',
      category: 'Clinical Topical',
      timeOfDay: 'Night',
      icon: LucideIcons.droplets,
    ),
    _RoutinePreset(
      title: 'Scalp Dermarolling (0.5mm)',
      subtitle: 'Roll gently across hairline for 5 minutes',
      category: 'Lifestyle',
      timeOfDay: 'Evening',
      icon: LucideIcons.scanLine,
    ),
    _RoutinePreset(
      title: 'Scalp Acupressure Massage',
      subtitle: 'Fingertip circular massage to boost circulation',
      category: 'Lifestyle',
      timeOfDay: 'Night',
      icon: LucideIcons.sparkles,
    ),
    _RoutinePreset(
      title: 'Biotin & Hair Multivitamin',
      subtitle: 'Take 1 tablet after meals with full glass of water',
      category: 'Oral Supplement',
      timeOfDay: 'Morning',
      icon: LucideIcons.pill,
    ),
    _RoutinePreset(
      title: 'Rosemary Scalp Tonic',
      subtitle: 'Spray 3-4 pumps and gently pat dry',
      category: 'Clinical Topical',
      timeOfDay: 'Morning',
      icon: LucideIcons.droplet,
    ),
    _RoutinePreset(
      title: 'Cold Water Scalp Rinse',
      subtitle: 'Cool rinse post-shower to close hair cuticles',
      category: 'Lifestyle',
      timeOfDay: 'Morning',
      icon: LucideIcons.waves,
    ),
  ];

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Clinical Topical',
      'label': 'Topical',
      'icon': LucideIcons.droplets,
      'color': Color(0xFF1E3A8A),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'name': 'Oral Supplement',
      'label': 'Supplement',
      'icon': LucideIcons.pill,
      'color': Color(0xFF059669),
      'bg': Color(0xFFECFDF5),
    },
    {
      'name': 'Lifestyle',
      'label': 'Lifestyle & Scalp',
      'icon': LucideIcons.sparkles,
      'color': Color(0xFFEA580C),
      'bg': Color(0xFFFFF7ED),
    },
  ];

  static const List<Map<String, dynamic>> _timesOfDay = [
    {'name': 'Morning', 'label': 'Morning', 'icon': LucideIcons.sun, 'time': '8:00 AM'},
    {'name': 'Afternoon', 'label': 'Afternoon', 'icon': LucideIcons.sunMedium, 'time': '1:00 PM'},
    {'name': 'Evening', 'label': 'Evening', 'icon': LucideIcons.sunset, 'time': '6:30 PM'},
    {'name': 'Night', 'label': 'Night', 'icon': LucideIcons.moon, 'time': '10:00 PM'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _applyPreset(_RoutinePreset preset) {
    HapticFeedback.lightImpact();
    setState(() {
      _titleController.text = preset.title;
      _subtitleController.text = preset.subtitle;
      _category = preset.category;
      _timeOfDay = preset.timeOfDay;
    });
  }

  Future<void> _saveCareStep() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      HapticFeedback.mediumImpact();
      AppToast.show(
        context,
        const SnackBar(
          content: Text('Please enter a title for this care step.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _titleFocus.requestFocus();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final subtitle = _subtitleController.text.trim().isEmpty
          ? 'As prescribed'
          : _subtitleController.text.trim();

      await context.read<CareCubit>().addCustomRoutineTask(
            title: title,
            subtitle: subtitle,
            category: _category,
            timeOfDay: _timeOfDay,
          );

      if (mounted) {
        AppToast.show(
          context,
          const SnackBar(
            content: Text('Routine step added successfully!'),
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
            content: Text('Could not save step. Stored locally.'),
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
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Icon Badge & Close Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Add Routine Step',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Add a personalized habit or medicine to your daily care routine.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neutral600,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20,
                            color: AppColors.neutral500,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Quick Preset Chips Section
                    Row(
                      children: const [
                        Icon(LucideIcons.zap, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'POPULAR HABITS & PRESETS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.6,
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
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final preset = _presets[index];
                          final isCurrent = _titleController.text.trim() == preset.title;

                          return InkWell(
                            onTap: () => _applyPreset(preset),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.primary5,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    preset.icon,
                                    size: 13,
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent
                                          ? Colors.white
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Selection
                    const Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _categories.map((cat) {
                        final isSelected = _category == cat['name'];
                        final color = cat['color'] as Color;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _category = cat['name'] as String);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? color : AppColors.neutral200,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 18,
                                      color: isSelected
                                          ? color
                                          : AppColors.neutral600,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat['label'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? color
                                            : AppColors.neutral700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Time of Day Selector
                    const Text(
                      'TIME OF DAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _timesOfDay.map((tod) {
                        final isSelected = _timeOfDay == tod['name'];

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _timeOfDay = tod['name'] as String);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.neutral100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.neutral200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tod['icon'] as IconData,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.neutral600,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tod['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.neutral800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Title Text Field
                    const Text(
                      'CARE STEP TITLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'e.g. Scalp Dermarolling (0.5mm)',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.neutral400,
                        ),
                        counterText: '',
                        prefixIcon: const Icon(
                          LucideIcons.penLine,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _titleController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  _titleController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.neutral50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle / Dosage Text Field
                    const Text(
                      'INSTRUCTIONS / DOSAGE (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subtitleController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'e.g. 5 minutes before serum or 1ml with dropper',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.neutral400,
                        ),
                        counterText: '',
                        prefixIcon: const Icon(
                          LucideIcons.fileText,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _subtitleController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  _subtitleController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.neutral50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Bar with Custom AppButton
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.neutral200.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: const BorderSide(color: AppColors.neutral300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: 'Save Care Step',
                      icon: const Icon(
                        LucideIcons.plus,
                        size: 18,
                        color: Colors.white,
                      ),
                      variant: AppButtonVariant.filled,
                      size: AppButtonSize.large,
                      height: 48,
                      borderRadius: BorderRadius.circular(16),
                      isLoading: _isSaving,
                      onPressed: _saveCareStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
