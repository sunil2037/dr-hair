import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';
import 'custom_cached_image.dart';
import 'photo_source_bottom_sheet.dart';

/// Reusable patient profile avatar picker with camera badge,
/// camera/gallery source selector sheet, and photo removal option.
class ProfilePhotoPicker extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? photoUrl;
  final bool isPhotoRemoved;
  final ValueChanged<({Uint8List bytes, String filename})> onPhotoSelected;
  final VoidCallback onPhotoRemoved;
  final double size;

  const ProfilePhotoPicker({
    super.key,
    this.photoBytes,
    this.photoUrl,
    this.isPhotoRemoved = false,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
    this.size = 94,
  });

  bool get hasPhoto =>
      photoBytes != null ||
      (!isPhotoRemoved && photoUrl != null && photoUrl!.isNotEmpty);

  Future<void> _pickPhoto(BuildContext context) async {
    HapticFeedback.selectionClick();
    await PhotoSourceBottomSheet.show(
      context,
      title: 'Profile Photo',
      subtitle: 'Choose a photo for your Dr.Hair patient profile',
      cameraSubtitle: 'Take a new profile photo with your camera',
      gallerySubtitle: 'Choose an existing photo from your library',
      removeTitle: 'Remove Profile Photo',
      removeSubtitle: 'Clear current photo and use the default avatar',
      hasExistingPhoto: hasPhoto,
      onSelectSource: (source) async {
        try {
          final picker = ImagePicker();
          final image = await picker.pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (image == null || !context.mounted) return;
          final bytes = await image.readAsBytes();
          if (!context.mounted) return;
          onPhotoSelected((bytes: bytes, filename: image.name));
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not access image: $e')));
        }
      },
      onRemovePhoto: onPhotoRemoved,
    );
  }

  Widget _buildAvatarImage() {
    if (photoBytes != null) {
      return Image.memory(
        photoBytes!,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
      );
    } else if (!isPhotoRemoved && photoUrl != null && photoUrl!.isNotEmpty) {
      return CustomCachedImage(
        imageUrl: photoUrl!,
        width: size - 4,
        height: size - 4,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: size - 4,
        height: size - 4,
        color: AppColors.primary5,
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.userRound,
          size: size * 0.47,
          color: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _pickPhoto(context),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildAvatarImage()),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _pickPhoto(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _pickPhoto(context),
            icon: const Icon(LucideIcons.imagePlus, size: 15),
            label: Text(
              hasPhoto ? 'Change photo' : 'Upload photo (optional)',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
