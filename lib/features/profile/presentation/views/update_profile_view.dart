import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../../../core/widgets/app_toast.dart';

class UpdateProfileView extends StatefulWidget {
  final ImagePicker? imagePicker;

  const UpdateProfileView({super.key, this.imagePicker});

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _selectedImagePath;
  bool _isPhotoRemoved = false;
  bool _isSaving = false;

  static const String _defaultAvatarUrl =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400';

  @override
  void initState() {
    super.initState();
    final authUser = context.read<AuthCubit?>()?.state.user;
    _nameController = TextEditingController(
      text: authUser?.name ?? 'Yashveer Soni',
    );
    _emailController = TextEditingController(text: 'yashveer@example.com');
    _phoneController = TextEditingController(
      text: authUser?.emailOrPhone ?? '+91 98765 43210',
    );
    _selectedImagePath = authUser?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    HapticFeedback.selectionClick();
    await PhotoSourceBottomSheet.show(
      context,
      title: 'Profile Photo',
      subtitle: 'Choose a photo for your Dr.Hair patient profile',
      cameraSubtitle: 'Take a new profile photo with your camera',
      gallerySubtitle: 'Choose an existing photo from your library',
      removeTitle: 'Remove Profile Photo',
      removeSubtitle: 'Clear current photo and use default avatar',
      hasExistingPhoto: _selectedImagePath != null || !_isPhotoRemoved,
      onSelectSource: (source) async {
        try {
          final picker = widget.imagePicker ?? ImagePicker();
          final XFile? image = await picker.pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (image != null && mounted) {
            setState(() {
              _selectedImagePath = image.path;
              _isPhotoRemoved = false;
            });
            HapticFeedback.lightImpact();
          }
        } catch (e) {
          if (mounted) {
            AppToast.show(context,
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Could not access photo: $e'),
              ),
            );
          }
        }
      },
      onRemovePhoto: () {
        setState(() {
          _selectedImagePath = null;
          _isPhotoRemoved = true;
        });
        HapticFeedback.lightImpact();
      },
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final authCubit = context.read<AuthCubit?>();
      authCubit?.updateProfile(
        name: _nameController.text.trim(),
        emailOrPhone: _phoneController.text.trim(),
        photoUrl: _selectedImagePath,
        clearPhoto: _isPhotoRemoved,
      );

      HapticFeedback.mediumImpact();

      Navigator.of(context).pop(true);
    }
  }

  Widget _buildAvatarImage() {
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
      if (_selectedImagePath!.startsWith('http')) {
        return ClipOval(
          child: CustomCachedImage(
            imageUrl: _selectedImagePath!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            borderRadius: 50,
          ),
        );
      }
      return ClipOval(
        child: Image.file(
          File(_selectedImagePath!),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderAvatar(),
        ),
      );
    }

    if (!_isPhotoRemoved) {
      return ClipOval(
        child: CustomCachedImage(
          imageUrl: _defaultAvatarUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          borderRadius: 50,
        ),
      );
    }

    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: AppColors.primary5,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.userRound,
        size: 46,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Interactive Avatar
              Center(
                child: Semantics(
                  label: 'Change profile photo',
                  button: true,
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _buildAvatarImage(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Inputs
              _buildInputField(
                label: 'Full Name',
                controller: _nameController,
                icon: LucideIcons.userRound,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Email Address',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'This field is required'
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.primary5,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
