import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Single option model for [CustomPaintDropdownField].
class CustomPaintDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const CustomPaintDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

/// Custom painter for drawing a medical-grade floating menu bubble
/// with an integrated upward-pointing pointer arrow, drop shadow,
/// and clinical border stroke.
class _DropdownBubblePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;
  final double arrowX;
  final double arrowWidth;
  final double arrowHeight;
  final double borderRadius;

  _DropdownBubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
    required this.arrowX,
    this.arrowWidth = 16.0,
    this.arrowHeight = 8.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyTop = arrowHeight;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, bodyTop, size.width, size.height - bodyTop),
      Radius.circular(borderRadius),
    );

    final path = Path();
    // Clamp arrow position so it stays comfortably within the rounded corners
    final clampedArrowX = arrowX.clamp(
      borderRadius + arrowWidth / 2 + 4,
      size.width - borderRadius - arrowWidth / 2 - 4,
    );
    final halfArrow = arrowWidth / 2;

    // Start at top-left corner after radius
    path.moveTo(borderRadius, bodyTop);

    // Line to left base of arrow
    path.lineTo(clampedArrowX - halfArrow, bodyTop);
    // Beak/apex of arrow
    path.lineTo(clampedArrowX, 0);
    // Line to right base of arrow
    path.lineTo(clampedArrowX + halfArrow, bodyTop);

    // Top-right corner
    path.lineTo(size.width - borderRadius, bodyTop);
    path.arcToPoint(
      Offset(size.width, bodyTop + borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Right edge and bottom-right corner
    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );

    // Bottom edge and bottom-left corner
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Left edge and top-left corner
    path.lineTo(0, bodyTop + borderRadius);
    path.arcToPoint(
      Offset(borderRadius, bodyTop),
      radius: Radius.circular(borderRadius),
    );
    path.close();

    // 1. Drop Shadow
    canvas.drawShadow(path, shadowColor, 14.0, true);

    // 2. Body Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Clinical Border Stroke
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 4. Subtle top highlight line inside body
    final highlightPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(borderRadius + 8, bodyTop + 2),
      Offset(size.width - borderRadius - 8, bodyTop + 2),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DropdownBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.arrowX != arrowX ||
        oldDelegate.shadowColor != shadowColor;
  }
}

/// Custom painter for an animated chevron indicator with rounded stroke caps.
class _DropdownChevronPainter extends CustomPainter {
  final double progress; // 0.0 = pointing down, 1.0 = pointing up
  final Color color;

  _DropdownChevronPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width * 0.32;

    // Interpolate vertical deflection between pointing down (arm positive) and pointing up (arm negative)
    final dy = (1.0 - 2.0 * progress) * (size.height * 0.22);

    final path = Path()
      ..moveTo(cx - arm, cy - dy)
      ..lineTo(cx, cy + dy)
      ..lineTo(cx + arm, cy - dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DropdownChevronPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// A custom-painted, medical-grade dropdown field matching the Dr. Hair login
/// input design language, featuring an anchored custom-painted popup menu.
class CustomPaintDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<CustomPaintDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hintText;
  final IconData? prefixIcon;
  final bool enabled;
  final bool requiredField;
  final bool showOptionalBadge;
  final String? errorText;
  final String? Function(T?)? validator;

  const CustomPaintDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText = 'Select an option',
    this.prefixIcon,
    this.enabled = true,
    this.requiredField = false,
    this.showOptionalBadge = true,
    this.errorText,
    this.validator,
  });

  @override
  State<CustomPaintDropdownField<T>> createState() =>
      _CustomPaintDropdownFieldState<T>();
}

class _CustomPaintDropdownFieldState<T> extends State<CustomPaintDropdownField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;

  String? _internalError;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(covariant CustomPaintDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      _internalError = widget.errorText;
    }
  }

  @override
  void dispose() {
    _removeOverlay(notify: false);
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animController.forward(from: 0.0);
  }

  void _closeMenu() {
    if (!_isOpen) return;
    _animController.reverse().then((_) {
      _removeOverlay();
    });
    setState(() => _isOpen = false);
  }

  void _removeOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(CustomPaintDropdownItem<T> item) {
    HapticFeedback.lightImpact();
    widget.onChanged?.call(item.value);
    if (widget.validator != null) {
      setState(() {
        _internalError = widget.validator!(item.value);
      });
    }
    _closeMenu();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 52);
    final fieldWidth = size.width;

    return OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Fullscreen barrier to dismiss dropdown on outside tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
                child: const SizedBox.expand(),
              ),
            ),
            // Floating anchored custom-painted dropdown bubble
            Positioned(
              width: fieldWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.scale(
                          scale: 0.94 + 0.06 * _expandAnimation.value,
                          alignment: const Alignment(-0.8, -1.0),
                          child: child,
                        ),
                      );
                    },
                    child: CustomPaint(
                      painter: _DropdownBubblePainter(
                        fillColor: Colors.white,
                        borderColor: AppColors.primary.withValues(alpha: 0.35),
                        shadowColor: AppColors.primary.withValues(alpha: 0.18),
                        arrowX: 32.0, // Aligned with the prefix icon
                        arrowWidth: 16.0,
                        arrowHeight: 8.0,
                        borderRadius: 18.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              indent: 12,
                              endIndent: 12,
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              final isSelected = item.value == widget.value;

                              return InkWell(
                                onTap: () => _selectItem(item),
                                borderRadius: BorderRadius.circular(12),
                                splashColor: AppColors.primary5,
                                highlightColor: AppColors.primary5.withValues(alpha: 0.5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary5
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      if (item.icon != null) ...[
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: 0.12)
                                                : AppColors.primary5.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 16,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.secondaryDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.primaryDark,
                                              ),
                                            ),
                                            if (item.subtitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.subtitle!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            LucideIcons.check,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveError = widget.errorText ?? _internalError;
    final hasError = effectiveError != null && effectiveError.isNotEmpty;

    CustomPaintDropdownItem<T>? selectedItem;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedItem = item;
        break;
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label Row (Identical to AuthInputField in Login view)
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              if (widget.requiredField) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ] else if (widget.showOptionalBadge) ...[
                const SizedBox(width: 6),
                const Text(
                  '(Optional)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Trigger Container
          Semantics(
            button: true,
            label: widget.label,
            child: InkWell(
              key: _fieldKey,
              onTap: widget.enabled ? _toggleMenu : null,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? AppColors.primary5.withValues(alpha: 0.3)
                      : AppColors.primary5.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasError
                        ? AppColors.danger
                        : (_isOpen ? AppColors.primary : AppColors.border),
                    width: hasError || _isOpen ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        widget.prefixIcon,
                        size: 18,
                        color: _isOpen
                            ? AppColors.primary
                            : AppColors.secondaryDark,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        selectedItem?.label ?? widget.hintText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedItem != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedItem != null
                              ? AppColors.primaryDark
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Custom-painted smoothly rotating chevron
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(16, 12),
                          painter: _DropdownChevronPainter(
                            progress: _animController.value,
                            color: _isOpen
                                ? AppColors.primary
                                : AppColors.secondaryDark,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error Message Display
          if (hasError) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                effectiveError,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

