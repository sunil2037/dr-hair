import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _textFadeAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Serene entrance animation (1200ms) with gentle ease
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onSplashComplete();
        }
      });

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    if (!mounted || _hasNavigated) return;
    final authState = context.read<AuthCubit>().state;
    if (authState.status == AuthStatus.loading) {
      return;
    }
    if (authState.status == AuthStatus.failure) {
      _continueToSignIn();
      return;
    }
    _hasNavigated = true;
    if (authState.requiresProfileCompletion ||
        authState.nextStep == 'COMPLETE_PROFILE') {
      context.go(RouteNames.completeProfile);
    } else if (authState.isAuthenticated) {
      final cachedCompleted =
          AppLocalCache.instance.getBool('has_completed_hair_test') ?? false;
      final cachedSkipped =
          AppLocalCache.instance.getBool('has_skipped_hair_test') ?? false;
      if ((authState.nextStep == 'ASSESSMENT' ||
              (!authState.hasCompletedAssessment && !cachedCompleted)) &&
          !cachedSkipped) {
        context.go(RouteNames.hairTest);
      } else {
        context.go(RouteNames.mainShell);
      }
    } else {
      context.go(RouteNames.signin);
    }
  }

  void _continueToSignIn() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    context.go(RouteNames.signin);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!_hasNavigated) {
          if (state.status == AuthStatus.failure) {
            _continueToSignIn();
          } else if (state.status != AuthStatus.loading) {
            _onSplashComplete();
          }
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) => Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: authState.status == AuthStatus.failure
                ? null
                : _onSplashComplete,
            child: Stack(
              children: [
                // 1. Serene Clinical Background Gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF8FAFC),
                          Color(0xFFEFF6F7),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Pure, Minimal Centered Emblem and Branding
                SafeArea(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circular emblem container
                              Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.primary100,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      blurRadius: 28,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Text(
                                        'DH',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Brand Title & Clinical Subtitle with smooth fade
                              FadeTransition(
                                opacity: _textFadeAnimation,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Dr. Hair',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary5,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primary100,
                                        ),
                                      ),
                                      child: const Text(
                                        'Advanced Hair & Scalp Clinic',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Error Retry Card (if session restore fails)
                if (authState.status == AuthStatus.failure)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0xFFF8FAFC).withValues(alpha: 0.94),
                      child: SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 420),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      LucideIcons.wifi,
                                      color: AppColors.secondaryDark,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Could not restore your session',
                                      style: TextStyle(
                                        color: AppColors.primaryDark,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      authState.errorMessage ??
                                          'Check your connection and try again.',
                                      style: const TextStyle(
                                        color: AppColors.secondaryDark,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: context
                                            .read<AuthCubit>()
                                            .restoreSession,
                                        icon: const Icon(LucideIcons.rotateCw),
                                        label: const Text('Try again'),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: TextButton(
                                        onPressed: _continueToSignIn,
                                        child: const Text('Sign in with phone'),
                                      ),
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }
}
