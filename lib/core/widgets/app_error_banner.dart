import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Reusable banner for displaying validation and runtime errors.
class AppErrorBanner extends StatelessWidget {
  final String message;
  final IconData icon;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.icon = LucideIcons.alertCircle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

