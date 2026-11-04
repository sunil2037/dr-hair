import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/session/session_coordinator.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';

enum _AuthMode { signIn, signUp }

enum _SignupStep { form, otp }

class SigninView extends StatefulWidget {
  const SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardEntranceController;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

  // Active Mode & Steps
  _AuthMode _activeMode = _AuthMode.signIn;
  _SignupStep _signupStep = _SignupStep.form;

  // Sign In Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  // Sign Up Controllers
  final _nameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  bool _obscureSignupPassword = true;
  String? _nameError;
  String? _signupEmailError;
  String? _signupPasswordError;
  String? _signupPhoneError;

  // OTP Controllers (for signup and inline verification)
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _entryMotionConfigured = false;
  final String _countryCode = '+91';
  String? _clipboardOtp;

  @override
  void initState() {
    super.initState();
    _cardEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _cardOpacity = CurvedAnimation(
      parent: _cardEntranceController,
      curve: Curves.easeOutCubic,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_cardOpacity);

    _checkClipboardForOtp();
  }

  Future<void> _checkClipboardForOtp() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final match = RegExp(r'\b\d{6}\b').firstMatch(text);
      if (match != null && mounted) {
        setState(() {
          _clipboardOtp = match.group(0);
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryMotionConfigured) return;
    _entryMotionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _cardEntranceController.value = 1;
    } else {
      _cardEntranceController.forward();
    }
  }

  @override
  void dispose() {
    _cardEntranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupPhoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
      const bool.fromEnvironment('flutter.test');

  void _onLoginSuccess() {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    String? redirect;
    try {
      redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    } catch (_) {
      // In tests or non-GoRouter contexts
    }

    if (authCubit.state.requiresProfileCompletion ||
        authCubit.state.nextStep == 'COMPLETE_PROFILE') {
      final target = redirect != null && redirect.isNotEmpty
          ? '${RouteNames.completeProfile}?redirect=${Uri.encodeComponent(redirect)}'
          : RouteNames.completeProfile;
      context.go(target);
    } else if (redirect != null &&
        redirect.isNotEmpty &&
        redirect != RouteNames.signin) {
      context.go(redirect);
    } else if (authCubit.state.nextStep == 'ASSESSMENT' ||
        !authCubit.state.hasCompletedAssessment) {
      final cachedCompleted =
          AppLocalCache.instance.getBool('has_completed_hair_test') ?? false;
      final cachedSkipped =
          AppLocalCache.instance.getBool('has_skipped_hair_test') ?? false;
      if (!cachedCompleted && !cachedSkipped) {
        context.go(RouteNames.hairTest);
      } else {
        _navigateToHome();
      }
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    try {
      context.go(RouteNames.mainShell);
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH ACTION HANDLERS
  // ---------------------------------------------------------------------------

  Future<void> _handlePasswordLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email address');
      hasError = true;
    } else {
      setState(() => _emailError = null);
    }

    if (password.isEmpty || password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    } else {
      setState(() => _passwordError = null);
    }

    if (hasError || _isLoading) return;

    setState(() => _isLoading = true);
    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.loginWithPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    } else {
      final errorMsg =
          authCubit.state.errorMessage ?? 'Invalid email or password.';
      if (errorMsg.toLowerCase().contains('suspended') ||
          errorMsg.toLowerCase().contains('blocked')) {
        SessionCoordinator.instance.showAccountBlockedDialog(
          context: context,
          message: errorMsg,
        );
      } else {
        AppToast.show(
          context,
          SnackBar(backgroundColor: AppColors.danger, content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    } else if (authCubit.state.requiresPhoneVerification) {
      _showSocialPhoneVerificationSheet();
    } else if (authCubit.state.errorMessage != null) {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authCubit.state.errorMessage!),
        ),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.loginWithApple();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    } else if (authCubit.state.requiresPhoneVerification) {
      _showSocialPhoneVerificationSheet();
    } else if (authCubit.state.errorMessage != null) {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authCubit.state.errorMessage!),
        ),
      );
    }
  }

  Future<void> _proceedToSignupOtp() async {
    final name = _nameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final phone = _signupPhoneController.text.trim();

    bool hasError = false;
    if (name.length < 2) {
      setState(() => _nameError = 'Enter your full name (minimum 2 letters)');
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _signupEmailError = 'Enter a valid email address');
      hasError = true;
    } else {
      setState(() => _signupEmailError = null);
    }

    if (password.length < 6) {
      setState(
        () => _signupPasswordError = 'Password must be at least 6 characters',
      );
      hasError = true;
    } else {
      setState(() => _signupPasswordError = null);
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      setState(
        () => _signupPhoneError = 'Please enter a valid 10-digit mobile number',
      );
      hasError = true;
    } else {
      setState(() => _signupPhoneError = null);
    }

    if (hasError || _isLoading) return;

    setState(() => _isLoading = true);
    final authCubit = context.read<AuthCubit>();
    final sent = await authCubit.sendSignupOtp(phone);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (sent) {
        _signupStep = _SignupStep.otp;
        for (final c in _otpControllers) {
          c.clear();
        }
      }
    });

    if (sent) {
      _checkClipboardForOtp();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _signupStep == _SignupStep.otp) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authCubit.state.errorMessage ?? 'Could not send verification OTP.',
          ),
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      AppToast.show(
        context,
        const SnackBar(
          content: Text('Enter the complete 6-digit verification code.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.registerWithPassword(
      name: _nameController.text.trim(),
      email: _signupEmailController.text.trim(),
      password: _signupPasswordController.text,
      phone: _signupPhoneController.text.trim(),
      otp: code,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _onLoginSuccess();
    } else {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(authCubit.state.errorMessage ?? 'Registration failed.'),
        ),
      );
    }
  }

  void _handleOtpChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var slot = index; slot < _otpControllers.length; slot++) {
        _otpControllers[slot].clear();
      }

      final count = digits.length
          .clamp(0, _otpControllers.length - index)
          .toInt();
      for (var offset = 0; offset < count; offset++) {
        _otpControllers[index + offset].text = digits[offset];
      }

      final nextIndex = index + count;
      if (nextIndex < _otpFocusNodes.length) {
        _otpFocusNodes[nextIndex].requestFocus();
      } else {
        _otpFocusNodes.last.requestFocus();
      }

      final fullCode = _otpControllers.map((c) => c.text).join();
      if (fullCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(fullCode)) {
        FocusScope.of(context).unfocus();
        if (!_isTesting) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && !_isLoading) {
              _submitRegistration();
            }
          });
        }
      }
      return;
    }

    if (digits.isNotEmpty) {
      if (value != digits) _otpControllers[index].text = digits;
      if (index < _otpFocusNodes.length - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      }

      final fullCode = _otpControllers.map((c) => c.text).join();
      if (fullCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(fullCode)) {
        FocusScope.of(context).unfocus();
        if (!_isTesting) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && !_isLoading) {
              _submitRegistration();
            }
          });
        }
      }
    } else if (index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _fillOtp(String code) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return;
    for (var index = 0; index < _otpControllers.length; index++) {
      _otpControllers[index].text = code[index];
    }
    FocusScope.of(context).unfocus();
    if (!_isTesting) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_isLoading) {
          _submitRegistration();
        }
      });
    }
  }

  Future<void> _resendSignupOtp() async {
    final phone = _signupPhoneController.text.trim();
    if (phone.isEmpty) return;
    final authCubit = context.read<AuthCubit>();
    final sent = await authCubit.sendSignupOtp(phone);
    if (!mounted) return;
    if (sent) {
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('A fresh verification code was sent to +91 $phone.'),
        ),
      );
    } else {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authCubit.state.errorMessage ?? 'Could not resend code.',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SOCIAL SIGNUP PHONE VERIFICATION SHEET
  // ---------------------------------------------------------------------------
  void _showSocialPhoneVerificationSheet() {
    final phoneCtrl = TextEditingController();
    final otpCtrls = List.generate(6, (_) => TextEditingController());
    final otpNodes = List.generate(6, (_) => FocusNode());
    bool otpSent = false;
    bool isSheetBusy = false;
    String? phoneErr;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Verify Mobile Number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'To protect your clinical records, please verify your mobile number with a quick OTP to complete registration.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (!otpSent) ...[
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary5.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🇮🇳',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _countryCode,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                              child: VerticalDivider(
                                color: AppColors.border,
                                thickness: 1,
                                width: 16,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: AppColors.primaryDark,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '98765 43210',
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (phoneErr != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          phoneErr!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Send Verification OTP',
                        isLoading: isSheetBusy,
                        onPressed: () async {
                          final p = phoneCtrl.text.trim();
                          if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(p)) {
                            setSheetState(
                              () => phoneErr =
                                  'Enter a valid 10-digit mobile number',
                            );
                            return;
                          }
                          setSheetState(() {
                            phoneErr = null;
                            isSheetBusy = true;
                          });
                          final cubit = sheetContext.read<AuthCubit>();
                          final sent = await cubit.sendSignupOtp(p);
                          setSheetState(() => isSheetBusy = false);
                          if (sent) {
                            setSheetState(() => otpSent = true);
                          } else {
                            if (sheetContext.mounted) {
                              AppToast.show(
                                sheetContext,
                                SnackBar(
                                  backgroundColor: AppColors.danger,
                                  content: Text(
                                    cubit.state.errorMessage ??
                                        'Could not send OTP.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ] else ...[
                      Text(
                        'Enter the 6-digit code sent to +91 ${phoneCtrl.text.trim()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 44,
                            height: 44,
                            child: TextField(
                              controller: otpCtrls[i],
                              focusNode: otpNodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.primary5,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty && i < 5) {
                                  otpNodes[i + 1].requestFocus();
                                } else if (val.isEmpty && i > 0) {
                                  otpNodes[i - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Verify & Complete Signup',
                        isLoading: isSheetBusy,
                        onPressed: () async {
                          final code = otpCtrls.map((c) => c.text).join();
                          if (code.length != 6) return;
                          setSheetState(() => isSheetBusy = true);
                          final cubit = sheetContext.read<AuthCubit>();
                          final verified = await cubit.verifySocialSignup(
                            phone: phoneCtrl.text.trim(),
                            otp: code,
                          );
                          setSheetState(() => isSheetBusy = false);
                          if (verified) {
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            _onLoginSuccess();
                          } else {
                            if (sheetContext.mounted) {
                              AppToast.show(
                                sheetContext,
                                SnackBar(
                                  backgroundColor: AppColors.danger,
                                  content: Text(
                                    cubit.state.errorMessage ??
                                        'OTP verification failed.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showForgotPasswordSheet() {
    final loginCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool otpSent = false;
    bool isResetBusy = false;
    String? errText;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      otpSent
                          ? 'Enter the 6-digit verification code and your new password.'
                          : 'Enter your registered email address or mobile number to receive a reset code.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (!otpSent) ...[
                      const Text(
                        'Registered Email or Mobile Number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: loginCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. user@gmail.com or 9876543210',
                          prefixIcon: const Icon(
                            LucideIcons.mail,
                            size: 18,
                            color: AppColors.secondaryDark,
                          ),
                          filled: true,
                          fillColor: AppColors.primary5.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      if (errText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          errText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Send Reset OTP',
                        isLoading: isResetBusy,
                        onPressed: () async {
                          final val = loginCtrl.text.trim();
                          if (val.isEmpty) {
                            setSheetState(
                              () =>
                                  errText = 'Enter your email or phone number',
                            );
                            return;
                          }
                          setSheetState(() {
                            errText = null;
                            isResetBusy = true;
                          });
                          final cubit = sheetContext.read<AuthCubit>();
                          final ok = await cubit.forgotPassword(val);
                          setSheetState(() => isResetBusy = false);
                          if (ok) {
                            setSheetState(() => otpSent = true);
                          } else {
                            setSheetState(
                              () => errText =
                                  cubit.state.errorMessage ??
                                  'Could not send code.',
                            );
                          }
                        },
                      ),
                    ] else ...[
                      const Text(
                        '6-Digit Reset Code',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '123456',
                          prefixIcon: const Icon(
                            LucideIcons.keyRound,
                            size: 18,
                            color: AppColors.secondaryDark,
                          ),
                          filled: true,
                          fillColor: AppColors.primary5.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'New Password (min 6 characters)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            LucideIcons.lock,
                            size: 18,
                            color: AppColors.secondaryDark,
                          ),
                          filled: true,
                          fillColor: AppColors.primary5.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      if (errText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          errText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Set New Password',
                        isLoading: isResetBusy,
                        onPressed: () async {
                          final code = otpCtrl.text.trim();
                          final newPass = newPassCtrl.text;
                          if (code.length != 6) {
                            setSheetState(() => errText = 'Enter 6-digit code');
                            return;
                          }
                          if (newPass.length < 6) {
                            setSheetState(
                              () => errText =
                                  'Password must be at least 6 characters',
                            );
                            return;
                          }
                          setSheetState(() {
                            errText = null;
                            isResetBusy = true;
                          });
                          final cubit = sheetContext.read<AuthCubit>();
                          final ok = await cubit.resetPassword(
                            login: loginCtrl.text.trim(),
                            otp: code,
                            newPassword: newPass,
                          );
                          setSheetState(() => isResetBusy = false);
                          if (ok) {
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            _emailController.text = loginCtrl.text.trim();
                            if (sheetContext.mounted) {
                              AppToast.show(
                                sheetContext,
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text(
                                    'Password reset successfully. You can now sign in.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            setSheetState(
                              () => errText =
                                  cubit.state.errorMessage ??
                                  'Password reset failed.',
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN SCAFFOLD BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Full-screen Hair Consultation Background Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF7F9FC), Color(0xFFEAF4F7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Back Button (Visible when Signup OTP step is active)
          if (_activeMode == _AuthMode.signUp && _signupStep == _SignupStep.otp)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _signupStep = _SignupStep.form;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Bottom Form Card with Smooth Animated Motion
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _cardOpacity,
                child: SlideTransition(
                  position: _cardSlide,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SafeArea(
                      bottom: true,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.14,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: AnimatedSize(
                          duration: Duration(
                            milliseconds: reduceMotion ? 0 : 300,
                          ),
                          curve: Curves.easeOutCubic,
                          child: AnimatedSwitcher(
                            duration: Duration(
                              milliseconds: reduceMotion ? 0 : 320,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _activeMode == _AuthMode.signIn
                                ? _buildSignInCard(context)
                                : _buildSignUpCard(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB SWITCHER WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary5.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeMode != _AuthMode.signIn) {
                  setState(() {
                    _activeMode = _AuthMode.signIn;
                    _emailError = null;
                    _passwordError = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeMode == _AuthMode.signIn
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeMode == _AuthMode.signIn
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _activeMode == _AuthMode.signIn
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: _activeMode == _AuthMode.signIn
                        ? AppColors.primaryDark
                        : AppColors.secondaryDark,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeMode != _AuthMode.signUp) {
                  setState(() {
                    _activeMode = _AuthMode.signUp;
                    _signupStep = _SignupStep.form;
                    _nameError = null;
                    _signupEmailError = null;
                    _signupPasswordError = null;
                    _signupPhoneError = null;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeMode == _AuthMode.signUp
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeMode == _AuthMode.signUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _activeMode == _AuthMode.signUp
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: _activeMode == _AuthMode.signUp
                        ? AppColors.primaryDark
                        : AppColors.secondaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIGN IN CARD (Email + Password + Social Auth)
  // ---------------------------------------------------------------------------
  Widget _buildSignInCard(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isBusy = _isLoading || authState.status == AuthStatus.loading;

    return Column(
      key: const ValueKey('card_signin'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabSwitcher(),
        const SizedBox(height: 20),

        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to your Dr.Hair patient account',
          style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
        ),
        const SizedBox(height: 20),

        // Email Field
        Row(
          children: const [
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            decoration: const InputDecoration(
              hintText: 'patient@example.com',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                LucideIcons.mail,
                size: 18,
                color: AppColors.secondaryDark,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_emailError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _emailError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Password Field
        Row(
          children: const [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handlePasswordLogin(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                LucideIcons.lock,
                size: 18,
                color: AppColors.secondaryDark,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: AppColors.secondaryDark,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _passwordError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        // Forgot Password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isBusy ? null : _showForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: isBusy ? null : _handlePasswordLogin,
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 18),

        // OR CONTINUE WITH Divider
        Row(
          children: const [
            Expanded(child: Divider(color: AppColors.border, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          ],
        ),

        const SizedBox(height: 16),

        // Social Sign In Buttons: Google and Apple
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: isBusy ? null : _handleGoogleSignIn,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: isBusy ? null : _handleAppleSignIn,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.apple, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Apple',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Bottom Switch Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Don\'t have an account? ',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeMode = _AuthMode.signUp;
                  _signupStep = _SignupStep.form;
                });
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildTermsAndPrivacyLinks(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SIGN UP CARD (Name + Email + Password + Phone OTP verification)
  // ---------------------------------------------------------------------------
  Widget _buildSignUpCard(BuildContext context) {
    if (_signupStep == _SignupStep.otp) {
      return _buildSignupOtpStep(context);
    }

    final authState = context.watch<AuthCubit>().state;
    final isBusy = _isLoading || authState.status == AuthStatus.loading;

    return Column(
      key: const ValueKey('card_signup'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabSwitcher(),
        const SizedBox(height: 20),

        const Text(
          'Create Patient Chart',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Join Dr.Hair for clinically verified hair care',
          style: TextStyle(fontSize: 12, color: AppColors.secondaryDark),
        ),
        const SizedBox(height: 20),

        // Full Name Field
        Row(
          children: const [
            Text(
              'Full Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Ramesh Kumar',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                LucideIcons.user,
                size: 18,
                color: AppColors.secondaryDark,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_nameError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _nameError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Email Field
        Row(
          children: const [
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            decoration: const InputDecoration(
              hintText: 'patient@example.com',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(
                LucideIcons.mail,
                size: 18,
                color: AppColors.secondaryDark,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_signupEmailError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _signupEmailError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Password Field
        Row(
          children: const [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _signupPasswordController,
            obscureText: _obscureSignupPassword,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            decoration: InputDecoration(
              hintText: 'Min 6 characters',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                LucideIcons.lock,
                size: 18,
                color: AppColors.secondaryDark,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignupPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: AppColors.secondaryDark,
                ),
                onPressed: () => setState(
                  () => _obscureSignupPassword = !_obscureSignupPassword,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_signupPasswordError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _signupPasswordError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Mobile Number Field (Required for Creating Patient Account)
        Row(
          children: const [
            Text(
              'Mobile Number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ).copyWith(left: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      _countryCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
                child: VerticalDivider(
                  color: AppColors.border,
                  thickness: 1,
                  width: 16,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _signupPhoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onSubmitted: (_) => _proceedToSignupOtp(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_signupPhoneError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _signupPhoneError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Send OTP & Continue Button
        AppButton(
          size: AppButtonSize.medium,
          height: 48,
          isLoading: isBusy,
          onPressed: _proceedToSignupOtp,
          text: 'Send Verification OTP',
          trailingIcon: const Icon(
            LucideIcons.arrowRight,
            size: 16,
            color: AppColors.card,
          ),
        ),

        const SizedBox(height: 18),

        // Bottom Switch Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account? ',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryDark),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeMode = _AuthMode.signIn;
                });
              },
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildTermsAndPrivacyLinks(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SIGN UP OTP VERIFICATION STEP
  // ---------------------------------------------------------------------------
  Widget _buildSignupOtpStep(BuildContext context) {
    final phoneDisplay = '$_countryCode ${_signupPhoneController.text.trim()}';
    final authState = context.watch<AuthCubit>().state;
    final countdown = authState.resendCountdown;
    final isBusy = _isLoading || authState.status == AuthStatus.loading;

    return Column(
      key: const ValueKey('step_signup_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Change number / back row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                context.read<AuthCubit?>()?.resetToPhoneStep();
                setState(() {
                  _signupStep = _SignupStep.form;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.arrowLeft,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Change Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ve sent a 6-digit OTP to $phoneDisplay',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 18),

        // 6 OTP Digit Inputs
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 44,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.primary5,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => _handleOtpChanged(index, value),
                ),
              );
            }),
          ),
        ),

        if (_clipboardOtp != null &&
            _otpControllers.every((c) => c.text.isEmpty)) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isBusy ? null : () => _fillOtp(_clipboardOtp!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clipboardPaste,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paste from clipboard: $_clipboardOtp',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        AppButton(
          size: AppButtonSize.large,
          height: 50,
          isLoading: isBusy,
          onPressed: _submitRegistration,
          text: 'Verify & Proceed',
        ),

        const SizedBox(height: 10),

        if (countdown > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 15,
                    color: AppColors.secondaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resend code in 00:${countdown.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.secondaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Center(
            child: TextButton.icon(
              onPressed: _resendSignupOtp,
              icon: const Icon(
                LucideIcons.rotateCw,
                size: 15,
                color: AppColors.primary,
              ),
              label: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TERMS AND PRIVACY LINKS
  // ---------------------------------------------------------------------------
  Widget _buildTermsAndPrivacyLinks() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Text(
            'By continuing, you agree to our',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.terms),
            child: const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(
            'and',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.privacyPolicy),
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
