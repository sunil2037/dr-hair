import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';

class UpdateProfileView extends StatefulWidget {
  final ImagePicker? imagePicker;

  const UpdateProfileView({super.key, this.imagePicker});

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  static const _genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _cityController;
  late final TextEditingController _occupationController;

  String? _selectedImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _gender;
  bool _isPhotoRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _occupationController = TextEditingController(text: user?.occupation ?? '');
    _selectedImageUrl = user?.photoUrl;
    _gender = _genderOptions.contains(user?.gender) ? user?.gender : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _occupationController.dispose();
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
      removeSubtitle: 'Clear current photo and use the default avatar',
      hasExistingPhoto:
          _selectedImageUrl != null ||
          _selectedImageBytes != null ||
          !_isPhotoRemoved,
      onSelectSource: (source) async {
        try {
          final picker = widget.imagePicker ?? ImagePicker();
          final image = await picker.pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          if (image == null || !mounted) return;
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            _selectedImageUrl = null;
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _isPhotoRemoved = false;
          });
          HapticFeedback.lightImpact();
        } catch (_) {
          if (!mounted) return;
          AppToast.show(
            context,
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Could not access that photo. Check photo permissions and try again.',
              ),
            ),
          );
        }
      },
      onRemovePhoto: () {
        setState(() {
          _selectedImageUrl = null;
          _selectedImageBytes = null;
          _selectedImageName = null;
          _isPhotoRemoved = true;
        });
        HapticFeedback.lightImpact();
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthCubit>();
    final currentUser = auth.state.user;
    final ageText = _ageController.text.trim();
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(ageText),
      clearAge: ageText.isEmpty && currentUser?.age != null,
      gender: _gender ?? '',
      city: _cityController.text.trim(),
      occupation: _occupationController.text.trim(),
      photoBytes: _selectedImageBytes,
      photoFilename: _selectedImageName,
      clearPhoto: _isPhotoRemoved,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) {
      AppToast.show(
        context,
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            auth.state.errorMessage ?? 'Could not update your profile.',
          ),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  Widget _buildAvatarImage() {
    if (_selectedImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _selectedImageBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderAvatar(),
        ),
      );
    }
    if (_selectedImageUrl?.isNotEmpty == true && !_isPhotoRemoved) {
      return ClipOval(
        child: CustomCachedImage(
          imageUrl: _selectedImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          borderRadius: 50,
        ),
      );
    }
    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() => Container(
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Semantics(
                  label: 'Change profile photo',
                  button: true,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickProfilePhoto,
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
              TextButton(
                onPressed: _isSaving ? null : _pickProfilePhoto,
                child: const Text('Change Profile Photo'),
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Full Name',
                controller: _nameController,
                icon: LucideIcons.userRound,
              ),
              const SizedBox(height: 18),
              _buildInputField(
                label: 'Email Address',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              const SizedBox(height: 18),
              _buildInputField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'To change your email or phone, the new contact must be verified first.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildInputField(
                label: 'Age (optional)',
                controller: _ageController,
                icon: LucideIcons.calendarDays,
                keyboardType: TextInputType.number,
                requiredField: false,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender (optional)',
                  prefixIcon: const Icon(
                    LucideIcons.usersRound,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.primary5,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: _genderOptions
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 18),
              _buildInputField(
                label: 'City (optional)',
                controller: _cityController,
                icon: LucideIcons.mapPin,
                requiredField: false,
              ),
              const SizedBox(height: 18),
              _buildInputField(
                label: 'Occupation (optional)',
                controller: _occupationController,
                icon: LucideIcons.briefcaseBusiness,
                requiredField: false,
              ),
              const SizedBox(height: 28),
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
                      ? const SizedBox.square(
                          dimension: 20,
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
    bool readOnly = false,
    bool requiredField = true,
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
          readOnly: readOnly,
          enabled: true,
          validator: (value) {
            final input = value?.trim() ?? '';
            if (readOnly) return null;
            if (requiredField && input.isEmpty) return 'This field is required';
            if (label == 'Full Name' && input.length < 2) {
              return 'Enter at least 2 characters';
            }
            if (label == 'Age (optional)' && input.isNotEmpty) {
              final age = int.tryParse(input);
              if (age == null || age < 1 || age > 120) {
                return 'Enter a whole number from 1 to 120';
              }
            }
            return null;
          },
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
