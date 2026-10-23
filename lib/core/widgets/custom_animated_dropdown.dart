import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Representation of a dropdown item with optional icon, subtitle, and badge tag.
class DropdownOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final String? tag;
  final bool isEnabled;

  const DropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.tag,
    this.isEnabled = true,
  });
}

/// Custom, reusable, animated dropdown with fluid motion, spring micro-interactions,
/// and a unified, seamless card layout (no disjointed seams or shifting borders).
class CustomAnimatedDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownOption<T>> items;
  final ValueChanged<T> onChanged;
  final String hintText;
  final IconData? prefixIcon;
  final String? label;
  final Color? fillColor;
  final double maxHeight;
  final EdgeInsetsGeometry contentPadding;

  const CustomAnimatedDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hintText = 'Select an option',
    this.prefixIcon,
    this.label,
    this.fillColor,
    this.maxHeight = 240,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 13,
    ),
  });

  /// Convenient constructor for simple lists of values
  factory CustomAnimatedDropdown.fromValues({
    Key? key,
    required List<T> values,
    required T? value,
    required ValueChanged<T> onChanged,
    required String Function(T) labelBuilder,
    String? Function(T)? subtitleBuilder,
    IconData? Function(T)? iconBuilder,
    String? Function(T)? tagBuilder,
    String hintText = 'Select an option',
    IconData? prefixIcon,
    String? label,
    Color? fillColor,
    double maxHeight = 240,
  }) {
    return CustomAnimatedDropdown<T>(
      key: key,
      value: value,
      onChanged: onChanged,
      hintText: hintText,
      prefixIcon: prefixIcon,
      label: label,
      fillColor: fillColor,
      maxHeight: maxHeight,
      items: values.map((val) {
        return DropdownOption<T>(
          value: val,
          label: labelBuilder(val),
          subtitle: subtitleBuilder != null ? subtitleBuilder(val) : null,
          icon: iconBuilder != null ? iconBuilder(val) : null,
          tag: tagBuilder != null ? tagBuilder(val) : null,
        );
      }).toList(),
    );
  }

  @override
  State<CustomAnimatedDropdown<T>> createState() =>
      _CustomAnimatedDropdownState<T>();
}

class _CustomAnimatedDropdownState<T> extends State<CustomAnimatedDropdown<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _borderColorAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _borderColorAnimation = ColorTween(
      begin: AppColors.border,
      end: AppColors.primary,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    HapticFeedback.selectionClick();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _selectItem(DropdownOption<T> item) {
    if (!item.isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onChanged(item.value);
    _toggleDropdown();
  }

  @override
  Widget build(BuildContext context) {
    DropdownOption<T>? selectedOption;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedOption = item;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Unified Dropdown Container (Single card with smooth accordion expansion)
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.fillColor ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColorAnimation.value ?? AppColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.03 + (0.05 * _animController.value),
                    ),
                    blurRadius: 6 + (6 * _animController.value),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trigger Tile (Always consistent, never morphs or deforms)
                    InkWell(
                      onTap: _toggleDropdown,
                      child: Padding(
                        padding: widget.contentPadding,
                        child: Row(
                          children: [
                            if (widget.prefixIcon != null) ...[
                              Icon(
                                widget.prefixIcon,
                                size: 16,
                                color: _isOpen
                                    ? AppColors.primary
                                    : AppColors.secondaryDark,
                              ),
                              const SizedBox(width: 10),
                            ],

                            // Selected Option Summary
                            Expanded(
                              child: selectedOption != null
                                  ? Row(
                                      children: [
                                        if (selectedOption.icon != null) ...[
                                          Icon(
                                            selectedOption.icon,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(
                                            selectedOption.label,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                        if (selectedOption.tag != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              selectedOption.tag!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : Text(
                                      widget.hintText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),

                            const SizedBox(width: 8),

                            // Animated Chevron
                            RotationTransition(
                              turns: _rotateAnimation,
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 18,
                                color: _isOpen
                                    ? AppColors.primary
                                    : AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanding Options inside the same unified card
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      alignment: Alignment.topCenter,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.border,
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: widget.maxHeight,
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: widget.items.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: AppColors.border,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = widget.items[index];
                                  final isSelected =
                                      item.value == widget.value;

                                  return InkWell(
                                    onTap: item.isEnabled
                                        ? () => _selectItem(item)
                                        : null,
                                    splashColor: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    highlightColor: AppColors.primary5,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary5
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          if (item.icon != null) ...[
                                            Icon(
                                              item.icon,
                                              size: 15,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.secondaryDark,
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.label,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: item.isEnabled
                                                        ? (isSelected
                                                              ? AppColors.primary
                                                              : AppColors
                                                                    .primaryDark)
                                                        : AppColors
                                                              .textSecondary
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                  ),
                                                ),
                                                if (item.subtitle != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.subtitle!,
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (item.tag != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : const Color(0xFFECFDF5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.tag!,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              LucideIcons.check,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
