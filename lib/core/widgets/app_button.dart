import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Available visual styles for [AppButton].
enum AppButtonVariant {
  filled,
  outlined,
  tonal,
  ghost,
}

/// Available predefined sizes for [AppButton].
enum AppButtonSize {
  small,
  medium,
  large,
}

/// A highly customizable, production-ready button component with smooth micro-motion,
/// loading states, variant styling, optional gradients, and tactile haptic feedback.
class AppButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final TextStyle? textStyle;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Color? splashColor;
  final Color? highlightColor;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final String? semanticLabel;
  final bool enableHaptics;

  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.textStyle,
    this.gradient,
    this.boxShadow,
    this.splashColor,
    this.highlightColor,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.semanticLabel,
    this.enableHaptics = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _effectiveDisabled =>
      widget.isDisabled || widget.isLoading || widget.onPressed == null;

  void _handleTap() {
    if (_effectiveDisabled) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  double get _defaultHeight {
    switch (widget.size) {
      case AppButtonSize.small:
        return 38;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 54;
    }
  }

  EdgeInsetsGeometry get _defaultPadding {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 15);
    }
  }

  double get _defaultFontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 14.5;
      case AppButtonSize.large:
        return 16;
    }
  }

  Color _resolveBackgroundColor(BuildContext context) {
    if (widget.backgroundColor != null) {
      return _effectiveDisabled
          ? widget.backgroundColor!.withValues(alpha: 0.5)
          : widget.backgroundColor!;
    }

    switch (widget.variant) {
      case AppButtonVariant.filled:
        return _effectiveDisabled
            ? AppColors.primary.withValues(alpha: 0.45)
            : AppColors.primary;
      case AppButtonVariant.outlined:
        return Colors.transparent;
      case AppButtonVariant.tonal:
        return _effectiveDisabled
            ? AppColors.primary5.withValues(alpha: 0.5)
            : AppColors.primary5;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _resolveForegroundColor(BuildContext context) {
    if (widget.foregroundColor != null) {
      return _effectiveDisabled
          ? widget.foregroundColor!.withValues(alpha: 0.5)
          : widget.foregroundColor!;
    }

    switch (widget.variant) {
      case AppButtonVariant.filled:
        return Colors.white;
      case AppButtonVariant.outlined:
        return _effectiveDisabled ? AppColors.textMuted : AppColors.primary;
      case AppButtonVariant.tonal:
        return _effectiveDisabled ? AppColors.textMuted : AppColors.primary;
      case AppButtonVariant.ghost:
        return _effectiveDisabled ? AppColors.textMuted : AppColors.primary;
    }
  }

  BorderSide _resolveBorderSide(BuildContext context) {
    final double width = widget.borderWidth ??
        (widget.variant == AppButtonVariant.outlined ? 1.5 : 0.0);

    if (widget.variant == AppButtonVariant.outlined) {
      final Color color = widget.borderColor ??
          (_effectiveDisabled ? AppColors.border : AppColors.primary);
      return BorderSide(color: color, width: width);
    }

    if (widget.borderColor != null) {
      return BorderSide(color: widget.borderColor!, width: width);
    }

    return BorderSide.none;
  }

  @override
  Widget build(BuildContext context) {
    final bool disableMotion = MediaQuery.disableAnimationsOf(context);
    final Duration motionDuration =
        disableMotion ? Duration.zero : const Duration(milliseconds: 140);

    final Color bgColor = _resolveBackgroundColor(context);
    final Color fgColor = _resolveForegroundColor(context);
    final BorderSide borderSide = _resolveBorderSide(context);
    final BorderRadius effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(28);

    final TextStyle effectiveTextStyle = (widget.textStyle ??
            TextStyle(
              fontFamily: 'Inter',
              fontSize: _defaultFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ))
        .copyWith(color: fgColor);

    return Semantics(
      button: true,
      enabled: !_effectiveDisabled,
      label: widget.semanticLabel ?? widget.text,
      child: AnimatedScale(
        scale: _isPressed && !_effectiveDisabled ? 0.96 : 1.0,
        duration: motionDuration,
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            boxShadow: widget.boxShadow ??
                (widget.variant == AppButtonVariant.filled &&
                        !_effectiveDisabled &&
                        widget.elevation != 0.0
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null),
          ),
          child: Material(
            color: widget.gradient == null ? bgColor : Colors.transparent,
            elevation: widget.elevation ?? 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: effectiveRadius,
              side: borderSide,
            ),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: effectiveRadius,
                gradient: widget.gradient,
              ),
              child: InkWell(
                borderRadius: effectiveRadius,
                onTapDown: _effectiveDisabled
                    ? null
                    : (_) => setState(() => _isPressed = true),
                onTapUp: _effectiveDisabled
                    ? null
                    : (_) => setState(() => _isPressed = false),
                onTapCancel: _effectiveDisabled
                    ? null
                    : () => setState(() => _isPressed = false),
                onTap: _effectiveDisabled ? null : _handleTap,
                splashColor: widget.splashColor ?? fgColor.withValues(alpha: 0.12),
                highlightColor:
                    widget.highlightColor ?? fgColor.withValues(alpha: 0.06),
                child: Container(
                  height: widget.height ?? _defaultHeight,
                  padding: widget.padding ?? _defaultPadding,
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? SizedBox(
                          width: _defaultFontSize + 6,
                          height: _defaultFontSize + 6,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                          ),
                        )
                      : (widget.child ??
                          Row(
                            mainAxisAlignment: widget.mainAxisAlignment,
                            crossAxisAlignment: widget.crossAxisAlignment,
                            mainAxisSize: widget.width == null
                                ? MainAxisSize.min
                                : MainAxisSize.max,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                const SizedBox(width: 8),
                              ],
                              if (widget.text != null)
                                Flexible(
                                  child: Text(
                                    widget.text!,
                                    style: effectiveTextStyle,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              if (widget.trailingIcon != null) ...[
                                const SizedBox(width: 8),
                                widget.trailingIcon!,
                              ],
                            ],
                          )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
