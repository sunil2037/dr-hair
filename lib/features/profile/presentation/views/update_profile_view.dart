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
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 18),
              const Text('Remove profile photo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              const SizedBox(height: 8),
              const Text('Your current profile photo will be permanently deleted from stored media when you save this change. You can upload another photo later.', style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.secondaryDark)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('Keep photo'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Remove photo'))),
              ]),
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
      padding: const EdgeInsets.all(20),
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
      backgroundColor: AppColors.background,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                                color: AppColors.primary.withValues(alpha: 0.18),
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
                              border: Border.all(color: Colors.white, width: 2.5),
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
                icon: const Icon(LucideIcons.image, size: 16),
                label: const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                  _buildInputField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: LucideIcons.userRound,
                    hintText: 'Enter your full name (e.g. Rahul Sharma)',
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    customValidator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return 'This field is required';
                      if (input.length < 2) return 'Enter at least 2 characters';
                      if (input.length > 50) return 'Name cannot exceed 50 characters';
                      if (RegExp(r'[0-9]').hasMatch(input)) {
                        return 'Name should not contain numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'Age (optional)',
                    controller: _ageController,
                    icon: LucideIcons.calendarDays,
                    hintText: 'e.g. 28',
                    keyboardType: TextInputType.number,
                    requiredField: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    customValidator: (value) {
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
                  _buildGenderField(),
                ],
              ),

              // ---------------------------------------------------------------
              // Card 2: Verified Contact Information
              // ---------------------------------------------------------------
              _buildSectionCard(
                title: 'Contact Information',
                icon: LucideIcons.shieldCheck,
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 12, color: AppColors.secondary),
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
                  _buildInputField(
                    label: 'Email Address',
                    controller: _emailController,
                    icon: LucideIcons.mail,
                    hintText: 'e.g. name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: LucideIcons.phone,
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
                  _buildInputField(
                    label: 'City (optional)',
                    controller: _cityController,
                    icon: LucideIcons.mapPin,
                    hintText: 'e.g. Mumbai, New Delhi, Bengaluru',
                    textCapitalization: TextCapitalization.words,
                    requiredField: false,
                    customValidator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return null;
                      if (input.length < 2) return 'Enter at least 2 characters';
                      if (input.length > 60) return 'City cannot exceed 60 characters';
                      if (RegExp(r'[0-9]').hasMatch(input)) {
                        return 'City should not contain numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildInputField(
                    label: 'Occupation (optional)',
                    controller: _occupationController,
                    icon: LucideIcons.briefcaseBusiness,
                    hintText: 'e.g. Software Engineer, Teacher, Doctor',
                    textCapitalization: TextCapitalization.words,
                    requiredField: false,
                    customValidator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) return null;
                      if (input.length < 2) return 'Enter at least 2 characters';
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
      // -----------------------------------------------------------------------
      // Sticky Bottom Action Bar with Save Changes Button
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.check, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.primary),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
          decoration: InputDecoration(
            hintText: 'Select your gender',
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: const Icon(
              LucideIcons.usersRound,
              color: AppColors.primary,
              size: 19,
            ),
            filled: true,
            fillColor: AppColors.primary5,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
          items: _genderOptions
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _gender = value),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    bool requiredField = true,
    String? Function(String?)? customValidator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            ] else ...[
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enabled: true,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: readOnly ? AppColors.secondaryDark : AppColors.primaryDark,
          ),
          validator: customValidator ??
              (value) {
                final input = value?.trim() ?? '';
                if (readOnly) return null;
                if (requiredField && input.isEmpty) {
                  return 'This field is required';
                }
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
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(
              icon,
              color: readOnly ? AppColors.textMuted : AppColors.primary,
              size: 19,
            ),
            suffixIcon: readOnly
                ? const Icon(
                    LucideIcons.lock,
                    color: AppColors.textMuted,
                    size: 16,
                  )
                : null,
            filled: true,
            fillColor: readOnly ? AppColors.surfaceMuted : AppColors.primary5,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.8,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
