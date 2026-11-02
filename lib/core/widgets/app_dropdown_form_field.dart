import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Clean, medical-grade reusable dropdown form field for Dr. Hair.
class AppDropdownFormField<T> extends StatelessWidget {
  final T? initialValue;
  final String labelText;
  final Widget? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final String? Function(T?)? validator;
  final ValueChanged<T?>? onChanged;
  final bool isBusy;

  const AppDropdownFormField({
    super.key,
    this.initialValue,
    required this.labelText,
    this.prefixIcon,
    required this.items,
    this.validator,
    this.onChanged,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      items: items,
      validator: validator,
      onChanged: isBusy ? null : onChanged,
    );
  }
}

