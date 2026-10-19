import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breathingController;
  Timer? _redirectTimer;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _breathingController = AnimationController(
      vsync: this,
      lowerBound: 0.985,
      upperBound: 1.015,
      value: 1,
      duration: const Duration(milliseconds: 1800),
    );
    _redirectTimer = Timer(const Duration(seconds: 2), _continueAsGuest);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _entranceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _continueAsGuest() {
    if (mounted) context.go(RouteNames.mainShell);
  }

  void _openLogin() {
    _redirectTimer?.cancel();
    context.go(RouteNames.signin);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F7FF), Color(0xFFE7F3F1)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _GlowOrb(
                size: 250,
                color: AppColors.secondary.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -90,
              child: _GlowOrb(
                size: 280,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _entranceController,
                          _breathingController,
                        ]),
                        builder: (context, child) {
                          final entrance = Curves.easeOutBack.transform(
                            _entranceController.value,
                          );
                          final breathing = reduceMotion
                              ? 1.0
                              : _breathingController.value;
                          return Opacity(
                            opacity: _entranceController.value,
                            child: Transform.translate(
                              offset: Offset(0, 22 * (1 - entrance)),
                              child: Transform.scale(
                                scale: entrance * breathing,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 300,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 194,
                                height: 194,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.78),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      blurRadius: 42,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 224,
                                height: 224,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.14,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/icon.png',
                                width: 280,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Text(
                                      'Dr.Hair',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                              ),
                              const Positioned(
                                top: 22,
                                right: 34,
                                child: _Sparkle(),
                              ),
                              const Positioned(
                                bottom: 18,
                                left: 42,
                                child: _Sparkle(size: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _entranceController,
                          curve: const Interval(0.25, 1, curve: Curves.easeOut),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'ROOTED IN CARE',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your hair health journey starts here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 44),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openLogin,
                          icon: const Icon(LucideIcons.logIn),
                          label: const Text('Login or create an account'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _redirectTimer?.cancel();
                          _continueAsGuest();
                        },
                        child: const Text('Continue as guest'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;

  const _Sparkle({this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.sparkles,
      size: size,
      color: AppColors.secondary.withValues(alpha: 0.72),
    );
  }
}
