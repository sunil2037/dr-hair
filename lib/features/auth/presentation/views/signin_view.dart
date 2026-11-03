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
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';
import '../../../../core/widgets/app_toast.dart';

enum _LoginStep { phone, otp }

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
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  _LoginStep _currentStep = _LoginStep.phone;
  bool _isLoading = false;
  bool _entryMotionConfigured = false;
  final String _countryCode = '+91';
  String? _phoneError;
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
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onPhoneChanged(String val) {
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    } else {
      setState(() {});
    }
  }

  void _onTopBackTapped() {
    if (_currentStep == _LoginStep.otp) {
      _editPhoneNumber();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _proceedToOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (_isLoading) return;
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(rawPhone)) {
      setState(() {
        _phoneError = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _phoneError = null;
      _isLoading = true;
    });

    final authCubit = context.read<AuthCubit>();
    // The API stores and matches Indian phone identities as the 10-digit
    // national number. Keep +91 as presentation only until the UI supports
    // selecting other countries.
    final sent = await authCubit.sendOtp(rawPhone);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (sent) {
        _currentStep = _LoginStep.otp;
        for (final c in _otpControllers) {
          c.clear();
        }
      }
    });
    if (sent) {
      _checkClipboardForOtp();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentStep == _LoginStep.otp) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    }
    if (!sent) {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authCubit.state.errorMessage ?? 'Could not send the code.',
          ),
        ),
      );
    }
  }

  void _editPhoneNumber() {
    FocusScope.of(context).unfocus();
    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _currentStep = _LoginStep.phone;
    });
    context.read<AuthCubit?>()?.resetToPhoneStep();
  }

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
      const bool.fromEnvironment('flutter.test');

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
              _verifyOtpAndLogin();
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
              _verifyOtpAndLogin();
            }
          });
        }
      }
    } else if (index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _fillOtp(String code, {bool autoSubmit = false}) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return;
    for (var index = 0; index < _otpControllers.length; index++) {
      _otpControllers[index].text = code[index];
    }
    FocusScope.of(context).unfocus();
    if (autoSubmit && !_isTesting) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_isLoading) {
          _verifyOtpAndLogin();
        }
      });
    }
  }

  Future<void> _resendOtp() async {
    final authCubit = context.read<AuthCubit>();
    final sent = await authCubit.resendOtp();
    if (!mounted) return;
    if (sent) {
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
    if (!sent) {
      AppToast.show(
        context,
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authCubit.state.errorMessage ?? 'Could not resend the code.',
          ),
        ),
      );
      return;
    }
    final phoneDisplay = '$_countryCode ${_phoneController.text.trim()}';
    AppToast.show(
      context,
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('A fresh code was sent to $phoneDisplay.'),
      ),
    );
  }

  Future<void> _verifyOtpAndLogin() async {
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
    final phone = _phoneController.text.trim();

    final success = await authCubit.verifyOtp(otp: code, phoneNumber: phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      String? redirect;
      try {
        redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
      } catch (_) {
        // SigninView can also be previewed in a plain MaterialApp in tests.
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
    } else {
      final errorMsg =
          authCubit.state.errorMessage ?? 'Code verification failed.';
      if (errorMsg.toLowerCase().contains('suspended by clinic administration') ||
          errorMsg.toLowerCase().contains('account has been suspended')) {
        SessionCoordinator.instance.showAccountBlockedDialog(
          context: context,
          message: errorMsg,
        );
      } else {
        AppToast.show(
          context,
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(errorMsg),
          ),
        );
      }
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

          // 2. Top Back Button (Only visible when OTP step is active)
          if (_currentStep == _LoginStep.otp)
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
                      onTap: _onTopBackTapped,
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

          // 3. Bottom Form Card with Attractive Animated Motion
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
                          horizontal: 16,
                          vertical: 16,
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
                            transitionBuilder: (child, animation) {
                              final isOtp =
                                  child.key == const ValueKey('step_otp');
                              final slideTween = isOtp
                                  ? Tween<Offset>(
                                      begin: const Offset(0.25, 0),
                                      end: Offset.zero,
                                    )
                                  : Tween<Offset>(
                                      begin: const Offset(-0.25, 0),
                                      end: Offset.zero,
                                    );

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideTween.animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _currentStep == _LoginStep.phone
                                ? _buildPhoneStep(context)
                                : _buildOtpStep(context),
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
  // STEP 1: Phone Number Input Card
  // ---------------------------------------------------------------------------
  Widget _buildPhoneStep(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isValid10Digits = RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(_phoneController.text.trim());
    final authState = context.watch<AuthCubit>().state;
    final isBusy = _isLoading || authState.status == AuthStatus.loading;

    return Column(
      key: const ValueKey('step_phone'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Subtitle
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to your Dr.Hair patient account',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondaryDark,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 22),

        // Input Label
        Row(
          children: [
            const Text(
              'Mobile Number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Phone Input Field with Country Code & 10-digit Restriction
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary5.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              // Country Code Pill
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
                        fontSize: 15,
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

              // 10-Digit Phone Text Field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: _onPhoneChanged,
                  onSubmitted: (_) => _proceedToOtp(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: Duration(milliseconds: reduceMotion ? 0 : 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: isValid10Digits
                    ? const Padding(
                        key: ValueKey('valid_phone'),
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          LucideIcons.circleCheck,
                          color: AppColors.success,
                          size: 20,
                        ),
                      )
                    : const SizedBox(key: ValueKey('invalid_phone')),
              ),
            ],
          ),
        ),

        if (_phoneError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  size: 14,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 6),
                Text(
                  _phoneError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Send Verification OTP Button
        AppButton(
          size: AppButtonSize.medium,
          height: 48,
          isLoading: isBusy,
          onPressed: _proceedToOtp,
          text: 'Send Verification OTP',
          trailingIcon: const Icon(
            LucideIcons.arrowRight,
            size: 16,
            color: AppColors.card,
          ),
        ),

        const SizedBox(height: 18),

        // OR Divider
        const SizedBox(height: 20),

        // Terms and Privacy Policy Links
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                'By signing in, you agree to our',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.terms),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                'and',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.privacyPolicy),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: OTP Verification Card
  // ---------------------------------------------------------------------------
  Widget _buildOtpStep(BuildContext context) {
    final phoneDisplay = '$_countryCode ${_phoneController.text.trim()}';
    final authState = context.watch<AuthCubit>().state;
    final countdown = authState.resendCountdown;
    final isBusy = _isLoading || authState.status == AuthStatus.loading;

    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back / Edit phone row inside card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _editPhoneNumber,
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
            fontSize: 13,
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

        // Verify & Proceed Button with AppButton
        AppButton(
          size: AppButtonSize.large,
          height: 50,
          isLoading: isBusy,
          onPressed: _verifyOtpAndLogin,
          text: 'Verify & Proceed',
        ),

        const SizedBox(height: 10),

        // Resend code option with 30s countdown from cubit
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
              onPressed: _resendOtp,
              icon: const Icon(
                LucideIcons.rotateCw,
                size: 15,
                color: AppColors.primary,
              ),
              label: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
