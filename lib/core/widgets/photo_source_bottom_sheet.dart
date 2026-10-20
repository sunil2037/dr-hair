import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Reusable modal bottom sheet component for selecting photo source (Camera, Gallery)
/// or removing an existing photo across the app (Hair Test, Profile, etc.).
class PhotoSourceBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String cameraTitle;
  final String cameraSubtitle;
  final String galleryTitle;
  final String gallerySubtitle;
  final String removeTitle;
  final String removeSubtitle;
  final bool hasExistingPhoto;
  final ValueChanged<ImageSource> onSelectSource;
  final VoidCallback? onRemovePhoto;

  const PhotoSourceBottomSheet({
    super.key,
    this.title = 'Upload Photo',
    this.subtitle,
    this.cameraTitle = 'Take Photo',
    this.cameraSubtitle = 'Open camera to capture a new photo',
    this.galleryTitle = 'Choose from Gallery',
    this.gallerySubtitle = 'Select an existing photo from library',
    this.removeTitle = 'Remove Photo',
    this.removeSubtitle = 'Clear current photo',
    this.hasExistingPhoto = false,
    required this.onSelectSource,
    this.onRemovePhoto,
  });

  /// Displays the photo source bottom sheet in a modal bottom sheet.
  static Future<T?> show<T>(
    BuildContext context, {
    String title = 'Upload Photo',
    String? subtitle,
    String cameraTitle = 'Take Photo',
    String cameraSubtitle = 'Open camera to capture a new photo',
    String galleryTitle = 'Choose from Gallery',
    String gallerySubtitle = 'Select an existing photo from library',
    String removeTitle = 'Remove Photo',
    String removeSubtitle = 'Clear current photo',
    bool hasExistingPhoto = false,
    required ValueChanged<ImageSource> onSelectSource,
    VoidCallback? onRemovePhoto,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => PhotoSourceBottomSheet(
        title: title,
        subtitle: subtitle,
        cameraTitle: cameraTitle,
        cameraSubtitle: cameraSubtitle,
        galleryTitle: galleryTitle,
        gallerySubtitle: gallerySubtitle,
        removeTitle: removeTitle,
        removeSubtitle: removeSubtitle,
        hasExistingPhoto: hasExistingPhoto,
        onSelectSource: (source) {
          Navigator.pop(sheetContext);
          onSelectSource(source);
        },
        onRemovePhoto: onRemovePhoto != null
            ? () {
                Navigator.pop(sheetContext);
                onRemovePhoto();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildSourceOption(
              context: context,
              icon: LucideIcons.camera,
              title: cameraTitle,
              subtitle: cameraSubtitle,
              onTap: () => onSelectSource(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              context: context,
              icon: LucideIcons.image,
              title: galleryTitle,
              subtitle: gallerySubtitle,
              onTap: () => onSelectSource(ImageSource.gallery),
            ),
            if (hasExistingPhoto && onRemovePhoto != null) ...[
              const SizedBox(height: 12),
              _buildSourceOption(
                context: context,
                icon: LucideIcons.trash2,
                title: removeTitle,
                subtitle: removeSubtitle,
                isDestructive: true,
                onTap: onRemovePhoto!,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.danger.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.danger.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.primary5,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.danger : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? AppColors.danger
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDestructive
                          ? AppColors.danger.withValues(alpha: 0.8)
                          : AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDestructive
                  ? AppColors.danger.withValues(alpha: 0.6)
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
