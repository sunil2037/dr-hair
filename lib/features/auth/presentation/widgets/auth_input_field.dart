import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

/// Reusable, medical-grade input field widget used across Dr. Hair authentication
/// flows and patient profile management.
class AuthInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final bool requiredField;
  final bool showOptionalBadge;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const AuthInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.requiredField = false,
    this.showOptionalBadge = false,
    this.validator,
    this.focusNode,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    if (validator != null) {
      return FormField<String>(
        initialValue: controller.text,
        validator: validator,
        builder: (fieldState) {
          final effectiveError = errorText ?? fieldState.errorText;
          return _buildField(
            context,
            effectiveError: effectiveError,
            onFieldChanged: (val) {
              fieldState.didChange(val);
              onChanged?.call(val);
            },
          );
        },
      );
    }

    return _buildField(context, effectiveError: errorText, onFieldChanged: onChanged);
  }

  Widget _buildField(
    BuildContext context, {
    String? effectiveError,
    ValueChanged<String>? onFieldChanged,
  }) {
    final hasError = effectiveError != null && effectiveError.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Field Label Row
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ] else if (showOptionalBadge) ...[
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

        // Input Container
        Container(
          decoration: BoxDecoration(
            color: (enabled && !readOnly)
                ? AppColors.primary5.withValues(alpha: 0.3)
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.border,
              width: hasError ? 1.2 : 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            onFieldSubmitted: onSubmitted,
            onChanged: onFieldChanged,
            autofillHints: autofillHints,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: readOnly ? AppColors.secondaryDark : AppColors.primaryDark,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon:
                  prefixWidget ??
                  (prefixIcon != null
                      ? Icon(
                          prefixIcon,
                          size: 18,
                          color: readOnly
                              ? AppColors.textMuted
                              : AppColors.secondaryDark,
                        )
                      : null),
              filled: false,
              suffixIcon: suffixIcon ??
                  (readOnly
                      ? const Icon(
                          LucideIcons.lock,
                          color: AppColors.textMuted,
                          size: 16,
                        )
                      : null),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Error Message
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
    );
  }
}
