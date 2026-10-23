import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_cached_image.dart';

// ============================================================================
// REUSABLE CARE SCAFFOLD & UI COMPONENTS
// ============================================================================

/// Standard scaffold with Dr.Hair navigation app bar, clean divider, and safe scrollable content.
class CarePageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;

  const CarePageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.mainShell);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: child,
        ),
      ),
    );
  }
}

/// Standard rounded surface card for care features with subtle border and elevation.
Widget careCard({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
  Color? backgroundColor,
  Border? border,
  BorderRadius? borderRadius,
}) => Container(
  width: double.infinity,
  margin: margin,
  padding: padding,
  decoration: BoxDecoration(
    color: backgroundColor ?? Colors.white,
    borderRadius: borderRadius ?? BorderRadius.circular(20),
    border: border ?? Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: child,
);

/// Section header with primary color tracking title and optional descriptive subtitle.
Widget careSectionHeader({required String title, String? subtitle}) => Padding(
  padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark),
        ),
      ],
    ],
  ),
);

/// Pill stat widget displaying label and highlighted value.
Widget careStatPill({
  required String label,
  required String value,
  Color? valueColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: valueColor ?? AppColors.primaryDark,
        ),
      ),
    ],
  );
}

/// Helper to render cached network image or local file image.
Widget buildCarePhotoWidget(String path, {double height = 180, BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http')) {
    return CustomCachedImage(
      imageUrl: path,
      height: height,
      width: double.infinity,
      fit: fit,
    );
  }
  final file = File(path);
  if (file.existsSync()) {
    return Image.file(
      file,
      height: height,
      width: double.infinity,
      fit: fit,
    );
  }
  return Container(
    height: height,
    color: AppColors.primary5,
    child: const Icon(LucideIcons.camera, color: AppColors.primary, size: 36),
  );
}

/// Helper for abbreviated month names.
String careMonthName(int month) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return m[(month - 1).clamp(0, 11)];
}
