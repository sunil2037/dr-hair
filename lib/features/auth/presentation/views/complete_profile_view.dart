import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _occupationController = TextEditingController();
  String? _gender;
  bool _submitting = false;
  String? _error;

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
    final login = auth.state.phoneNumber?.trim() ?? '';
    if (login.isEmpty) {
      setState(
        () => _error =
            'Your verified sign-in session expired. Please sign in again.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final success = await auth.completeProfile(
      verifiedLogin: login,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty
          ? null
          : _occupationController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = success
          ? null
          : auth.state.errorMessage ?? 'Could not save your profile.';
    });
    if (success) context.go(RouteNames.mainShell);
  }

  @override
  Widget build(BuildContext context) {
    final verifiedLogin = context.select<AuthCubit, String>(
      (cubit) => cubit.state.phoneNumber ?? '',
    );
    final authStatus = context.select<AuthCubit, AuthStatus>(
      (cubit) => cubit.state.status,
    );
    final isBusy = _submitting || authStatus == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your sign-in is verified',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verifiedLogin,
                            style: const TextStyle(
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Contact details stay tied to the identity you verified.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Tell us a little about yourself',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your name is required. The other details are optional and help personalize your care.',
                style: TextStyle(color: AppColors.secondaryDark, height: 1.45),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(LucideIcons.userRound),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) return 'Enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Age (optional)',
                  prefixIcon: Icon(LucideIcons.calendarDays),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final age = value?.trim() ?? '';
                  if (age.isEmpty) return null;
                  final parsedAge = int.tryParse(age);
                  if (parsedAge == null || parsedAge < 1 || parsedAge > 120) {
                    return 'Enter a whole number from 1 to 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender (optional)',
                  prefixIcon: Icon(LucideIcons.usersRound),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(
                    value: 'Non-binary',
                    child: Text('Non-binary'),
                  ),
                  DropdownMenuItem(
                    value: 'Prefer not to say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: isBusy
                    ? null
                    : (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'City (optional)',
                  prefixIcon: Icon(LucideIcons.mapPin),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _occupationController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Occupation (optional)',
                  prefixIcon: Icon(LucideIcons.briefcaseBusiness),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isBusy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isBusy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save and continue'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isBusy
                    ? null
                    : () {
                        context.read<AuthCubit>().signOut();
                        context.go(RouteNames.signin);
                      },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
