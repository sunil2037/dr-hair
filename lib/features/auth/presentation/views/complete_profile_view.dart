import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/storage/secure_session_store.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown_form_field.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/widgets/profile_photo_picker.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';

/// Full-screen view for the /complete-profile route.
class CompleteProfileView extends StatelessWidget {
  const CompleteProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompleteProfileSheetContent(isBottomSheet: false);
  }
}

/// Modal bottom sheet representation for contextual profile completion
/// (e.g., before booking a clinical appointment or completing demographics).
class CompleteProfileBottomSheet extends StatelessWidget {
  final bool requireAgeAndGender;
  final String? title;
  final String? subtitle;

  const CompleteProfileBottomSheet({
    super.key,
    this.requireAgeAndGender = false,
    this.title,
    this.subtitle,
  });

  /// Displays the profile completion form inside a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    bool requireAgeAndGender = false,
    String? title,
    String? subtitle,
  }) {
    final authCubit = context.read<AuthCubit>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CompleteProfileBottomSheet(
          requireAgeAndGender: requireAgeAndGender,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompleteProfileSheetContent(
      isBottomSheet: true,
      requireAgeAndGender: requireAgeAndGender,
      title: title,
      subtitle: subtitle,
    );
  }
}

class CompleteProfileSheetContent extends StatefulWidget {
  final bool isBottomSheet;
  final bool requireAgeAndGender;
  final String? title;
  final String? subtitle;

  const CompleteProfileSheetContent({
    super.key,
    required this.isBottomSheet,
    this.requireAgeAndGender = false,
    this.title,
    this.subtitle,
  });

  @override
  State<CompleteProfileSheetContent> createState() =>
      _CompleteProfileSheetContentState();
}

class _CompleteProfileSheetContentState
    extends State<CompleteProfileSheetContent> {
  static const _genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _cityController;
  late final TextEditingController _occupationController;

  String? _gender;
  Uint8List? _photoBytes;
  String? _photoFilename;
  String? _existingPhotoUrl;
  bool _isPhotoRemoved = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(
      text: user?.age != null ? '${user!.age}' : '',
    );
    _cityController = TextEditingController(text: user?.city ?? '');
    _occupationController = TextEditingController(text: user?.occupation ?? '');
    _gender = _genderOptions.contains(user?.gender) ? user?.gender : null;
    _existingPhotoUrl = user?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthCubit>();
    final currentUser = auth.state.user;
    final isExistingUser =
        auth.state.isRegistered &&
        currentUser != null &&
        currentUser.id.trim().isNotEmpty;

    var login = auth.state.phoneNumber?.trim() ?? '';
    if (login.isEmpty && currentUser != null) {
      login = currentUser.phone?.trim() ?? '';
      if (login.isEmpty) {
        login = currentUser.emailOrPhone.trim();
      }
    }
    if (login.isEmpty) {
      final storedLogin = await SecureSessionStore().readLogin();
      if (storedLogin != null && storedLogin.trim().isNotEmpty) {
        login = storedLogin.trim();
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final age = ageStr.isEmpty ? null : int.tryParse(ageStr);
    final city = _cityController.text.trim().isEmpty
        ? null
        : _cityController.text.trim();
    final occupation = _occupationController.text.trim().isEmpty
        ? null
        : _occupationController.text.trim();

    bool success = false;
    if (isExistingUser) {
      success = await auth.updateProfile(
        name: name,
        age: age,
        clearAge: age == null,
        gender: _gender,
        city: city,
        occupation: occupation,
        photoBytes: _photoBytes,
        photoFilename: _photoFilename,
        clearPhoto: _isPhotoRemoved,
      );
    } else {
      if (login.isEmpty) {
        setState(() {
          _submitting = false;
          _error =
              'Your verified sign-in session expired. Please sign in again.';
        });
        return;
      }
      success = await auth.completeProfile(
        verifiedLogin: login,
        name: name,
        age: age,
        gender: _gender,
        city: city,
        occupation: occupation,
      );
      if (success && (_photoBytes != null || _isPhotoRemoved)) {
        await auth.updateProfile(
          photoBytes: _photoBytes,
          photoFilename: _photoFilename,
          clearPhoto: _isPhotoRemoved,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = success
          ? null
          : auth.state.errorMessage ?? 'Could not save your profile.';
    });

    if (success) {
      if (widget.isBottomSheet) {
        Navigator.of(context).pop(true);
      } else {
        try {
          final redirect = GoRouterState.of(context)
              .uri
              .queryParameters['redirect'];
          if (redirect != null &&
              redirect.isNotEmpty &&
              redirect != RouteNames.signin &&
              redirect != RouteNames.completeProfile) {
            context.go(redirect);
          } else {
            // First-time account creation: show assessment screen, do not show home screen directly.
            context.go(RouteNames.hairTest);
          }
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      }
    }
  }

  Widget _buildFormFields(bool isBusy) {
    final requireAgeAndGender = widget.requireAgeAndGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reusable Profile Photo Picker
        ProfilePhotoPicker(
          photoBytes: _photoBytes,
          photoUrl: _existingPhotoUrl,
          isPhotoRemoved: _isPhotoRemoved,
          onPhotoSelected: (selected) {
            setState(() {
              _photoBytes = selected.bytes;
              _photoFilename = selected.filename;
              _isPhotoRemoved = false;
            });
          },
          onPhotoRemoved: () {
            setState(() {
              _photoBytes = null;
              _photoFilename = null;
              _existingPhotoUrl = null;
              _isPhotoRemoved = true;
            });
          },
        ),
        const SizedBox(height: 14),

        // Full Name (Required)
        AppTextFormField(
          controller: _nameController,
          labelText: 'Full name *',
          hintText: 'Enter your full name',
          prefixIcon: const Icon(LucideIcons.userRound, size: 20),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.length < 2) return 'Please enter your full name';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Age (Optional unless requireAgeAndGender is true)
        AppTextFormField(
          controller: _ageController,
          labelText: requireAgeAndGender ? 'Age *' : 'Age (optional)',
          hintText: 'e.g. 28',
          prefixIcon: const Icon(LucideIcons.calendarDays, size: 20),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final age = value?.trim() ?? '';
            if (age.isEmpty) {
              if (requireAgeAndGender) {
                return 'Please enter your age';
              }
              return null;
            }
            final parsedAge = int.tryParse(age);
            if (parsedAge == null || parsedAge < 1 || parsedAge > 120) {
              return 'Enter a valid age between 1 and 120';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Gender (Optional unless requireAgeAndGender is true)
        AppDropdownFormField<String>(
          initialValue: _gender,
          labelText: requireAgeAndGender ? 'Gender *' : 'Gender (optional)',
          prefixIcon: const Icon(LucideIcons.usersRound, size: 20),
          items: _genderOptions
              .map(
                (gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender)),
              )
              .toList(),
          validator: (value) {
            if (requireAgeAndGender &&
                (value == null || value.trim().isEmpty)) {
              return 'Please select your gender';
            }
            return null;
          },
          isBusy: isBusy,
          onChanged: (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: 14),

        // City (Optional)
        AppTextFormField(
          controller: _cityController,
          labelText: 'City (optional)',
          hintText: 'e.g. Jaipur',
          prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),

        // Occupation (Optional)
        AppTextFormField(
          controller: _occupationController,
          labelText: 'Occupation (optional)',
          hintText: 'e.g. Consultant',
          prefixIcon: const Icon(LucideIcons.briefcaseBusiness, size: 20),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),

        if (_error != null) ...[
          const SizedBox(height: 14),
          AppErrorBanner(message: _error!),
        ],
      ],
    );
  }

  Widget _buildFixedBottomButton(bool isBusy) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        widget.isBottomSheet
            ? 12
            : (16 + MediaQuery.of(context).padding.bottom),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        bottom: widget.isBottomSheet,
        child: AppButton(
          text: 'Save & Continue',
          isLoading: isBusy,
          onPressed: isBusy ? null : _submit,
          height: 50,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.select<AuthCubit, AuthStatus>(
      (cubit) => cubit.state.status,
    );
    final isBusy = _submitting || authStatus == AuthStatus.loading;

    if (widget.isBottomSheet) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final maxHeight = MediaQuery.of(context).size.height * 0.90;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Bottom Sheet Title & Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Complete your profile',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle ??
                                (widget.requireAgeAndGender
                                    ? 'Age and gender are required before booking an in-clinic consultation.'
                                    : 'Full name is required. Other fields are optional.'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondaryDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: isBusy
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Form(key: _formKey, child: _buildFormFields(isBusy)),
                ),
              ),

              // Pinned Bottom Button (Not scrollable)
              _buildFixedBottomButton(isBusy),
            ],
          ),
        ),
      );
    }

    // Full-screen route presentation
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Complete your profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const Text(
                'Tell us a little about yourself',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.secondaryDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormFields(isBusy),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFixedBottomButton(isBusy),
    );
  }
}
