import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/custom_paint_dropdown.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_input_field.dart';

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
          if (image == null) return;
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
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
        _confirmProfilePhotoRemoval();
      },
    );
  }

  Future<void> _confirmProfilePhotoRemoval() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Remove profile photo?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your current profile photo will be permanently deleted from stored media when you save this change. You can upload another photo later.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Remove photo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _selectedImageUrl = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _isPhotoRemoved = true;
    });
    HapticFeedback.lightImpact();
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
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholderAvatar(),
        ),
      );
    }
    if (_selectedImageUrl?.isNotEmpty == true && !_isPhotoRemoved) {
      return ClipOval(
        child: CustomCachedImage(
          imageUrl: _selectedImageUrl!,
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          borderRadius: 52,
        ),
      );
    }
    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() => Container(
    width: 104,
    height: 104,
    decoration: const BoxDecoration(
      color: AppColors.primary5,
      shape: BoxShape.circle,
    ),
    child: const Icon(
      LucideIcons.userRound,
      size: 48,
      color: AppColors.primary,
    ),
  );

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? badge,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),
      body: Skeletonizer(
        enabled: _isSaving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ---------------------------------------------------------------
                // Avatar & Photo Upload Header
                // ---------------------------------------------------------------
                Center(
                  child: Semantics(
                    label: 'Change profile photo',
                    button: true,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _pickProfilePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _buildAvatarImage(),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _isSaving ? null : _pickProfilePhoto,
                  icon: const Icon(
                    LucideIcons.camera,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Change Profile Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------------------------
                // Card 1: Personal Information
                // ---------------------------------------------------------------
                _buildSectionCard(
                  title: 'Personal Details',
                  icon: LucideIcons.userRound,
                  children: [
                    AuthInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: LucideIcons.userRound,
                      hintText: 'Enter your full name (e.g. Rahul Sharma)',
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      requiredField: true,
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return 'This field is required';
                        if (input.length < 2) {
                          return 'Enter at least 2 characters';
                        }
                        if (input.length > 50) {
                          return 'Name cannot exceed 50 characters';
                        }
                        if (RegExp(r'[0-9]').hasMatch(input)) {
                          return 'Name should not contain numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AuthInputField(
                      label: 'Age',
                      controller: _ageController,
                      prefixIcon: LucideIcons.calendarDays,
                      hintText: 'e.g. 28',
                      keyboardType: TextInputType.number,
                      requiredField: false,
                      showOptionalBadge: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        final age = int.tryParse(input);
                        if (age == null || age < 1 || age > 120) {
                          return 'Enter a whole number from 1 to 120';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    CustomPaintDropdownField<String>(
                      label: 'Gender',
                      value: _gender,
                      prefixIcon: LucideIcons.usersRound,
                      hintText: 'Select your gender',
                      requiredField: false,
                      showOptionalBadge: true,
                      items: const [
                        CustomPaintDropdownItem(
                          value: 'Male',
                          label: 'Male',
                          subtitle: 'Biological male or masculine',
                          icon: LucideIcons.user,
                        ),
                        CustomPaintDropdownItem(
                          value: 'Female',
                          label: 'Female',
                          subtitle: 'Biological female or feminine',
                          icon: LucideIcons.userRound,
                        ),
                        CustomPaintDropdownItem(
                          value: 'Non-binary',
                          label: 'Non-binary',
                          subtitle: 'Non-binary or gender non-conforming',
                          icon: LucideIcons.sparkles,
                        ),
                        CustomPaintDropdownItem(
                          value: 'Prefer not to say',
                          label: 'Prefer not to say',
                          subtitle: 'Keep this private',
                          icon: LucideIcons.shieldCheck,
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _gender = value),
                    ),
                  ],
                ),

                // ---------------------------------------------------------------
                // Card 2: Verified Contact Information
                // ---------------------------------------------------------------
                _buildSectionCard(
                  title: 'Contact Information',
                  icon: LucideIcons.shieldCheck,
                  badge: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    AuthInputField(
                      label: 'Email Address',
                      controller: _emailController,
                      prefixIcon: LucideIcons.mail,
                      hintText: 'e.g. name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                    ),
                    const SizedBox(height: 18),
                    AuthInputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      prefixIcon: LucideIcons.phone,
                      hintText: 'e.g. +91 98765 43210',
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary5,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To change your email or phone, the new contact must be verified first.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ---------------------------------------------------------------
                // Card 3: Additional Location & Profession
                // ---------------------------------------------------------------
                _buildSectionCard(
                  title: 'Additional Details',
                  icon: LucideIcons.mapPin,
                  children: [
                    AuthInputField(
                      label: 'City',
                      controller: _cityController,
                      prefixIcon: LucideIcons.mapPin,
                      hintText: 'e.g. Mumbai, New Delhi, Bengaluru',
                      textCapitalization: TextCapitalization.words,
                      requiredField: false,
                      showOptionalBadge: true,
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        if (input.length < 2) {
                          return 'Enter at least 2 characters';
                        }
                        if (input.length > 60) {
                          return 'City cannot exceed 60 characters';
                        }
                        if (RegExp(r'[0-9]').hasMatch(input)) {
                          return 'City should not contain numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AuthInputField(
                      label: 'Occupation',
                      controller: _occupationController,
                      prefixIcon: LucideIcons.briefcaseBusiness,
                      hintText: 'e.g. Software Engineer, Teacher, Doctor',
                      textCapitalization: TextCapitalization.words,
                      requiredField: false,
                      showOptionalBadge: true,
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        if (input.length < 2) {
                          return 'Enter at least 2 characters';
                        }
                        if (input.length > 60) {
                          return 'Occupation cannot exceed 60 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // -----------------------------------------------------------------------
      // Sticky Bottom Action Bar with Custom AppButton
      // -----------------------------------------------------------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Skeletonizer(
            enabled: _isSaving,
            child: AppButton(
              text: _isSaving ? 'Saving Changes...' : 'Save Changes',
              isLoading: false,
              onPressed: _isSaving ? null : _saveProfile,
              borderRadius: BorderRadius.circular(28),
              height: 52,
            ),
          ),
        ),
      ),
    );
  }
}
