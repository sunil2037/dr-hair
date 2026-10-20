import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../viewmodels/auth_cubit.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _motionController;
  bool _motionConfigured = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Keep the brand moment brief, then continue as soon as the entrance lands.
    _entranceController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 850),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _onSplashComplete();
        });
    _entranceController.forward();

    // Continuous soothing motion loop (vitality ripples, levitation, sparkles)
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1.0;
    } else {
      _motionController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _onSplashComplete() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    final authCubit = context.read<AuthCubit?>();
    final isAuthenticated = authCubit?.state.isAuthenticated ?? false;
    if (isAuthenticated) {
      context.go(RouteNames.mainShell);
    } else {
      context.go(RouteNames.signin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSplashComplete,
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

            // 2. Soft Ambient Lighting Orbs
            Positioned(
              top: -60,
              right: -60,
              child: _AmbientGlow(
                size: 260,
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _AmbientGlow(
                size: 300,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),

            // 3. Pure, Minimal Centered Emblem and Branding
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Emblem with Concentric Vitality Waves & Sparkles
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _entranceController,
                          _motionController,
                        ]),
                        builder: (context, child) {
                          final entranceCurved = Curves.easeOutBack.transform(
                            _entranceController.value,
                          );
                          final motionVal = reduceMotion
                              ? 0.0
                              : _motionController.value;
                          final floatOffset = reduceMotion
                              ? 0.0
                              : math.sin(motionVal * 2 * math.pi) * 4.0;

                          return Opacity(
                            opacity: _entranceController.value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                (24 * (1 - entranceCurved)) + floatOffset,
                              ),
                              child: Transform.scale(
                                scale: entranceCurved,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _HeroEmblem(
                          motionController: _motionController,
                          reduceMotion: reduceMotion,
                        ),
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

/// Concentric vitality ripples and glassmorphic emblem centerpiece
class _HeroEmblem extends StatelessWidget {
  final AnimationController motionController;
  final bool reduceMotion;

  const _HeroEmblem({
    required this.motionController,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vitality Wave 1
          if (!reduceMotion)
            AnimatedBuilder(
              animation: motionController,
              builder: (context, _) {
                final t = motionController.value;
                final scale = 0.88 + 0.40 * t;
                final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.22;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: opacity),
                        width: 1.8,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Vitality Wave 2 (Phase offset by 0.5)
          if (!reduceMotion)
            AnimatedBuilder(
              animation: motionController,
              builder: (context, _) {
                final t = (motionController.value + 0.5) % 1.0;
                final scale = 0.88 + 0.40 * t;
                final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.18;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: opacity),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Glassmorphic Card Container
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.94),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(
                  'assets/images/icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'Dr.Hair',
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
          ),

          // Twinkling Sparkle 1 (Top-Right)
          Positioned(
            top: 24,
            right: 28,
            child: _TwinkleSparkle(
              motionController: motionController,
              size: 15,
              color: AppColors.secondary,
              phaseOffset: 0.0,
            ),
          ),

          // Twinkling Sparkle 2 (Bottom-Left)
          Positioned(
            bottom: 26,
            left: 32,
            child: _TwinkleSparkle(
              motionController: motionController,
              size: 11,
              color: AppColors.primary,
              phaseOffset: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// An animated micro-twinkle sparkle that scales and rotates smoothly
class _TwinkleSparkle extends StatelessWidget {
  final AnimationController motionController;
  final double size;
  final Color color;
  final double phaseOffset;

  const _TwinkleSparkle({
    required this.motionController,
    required this.size,
    required this.color,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motionController,
      builder: (context, _) {
        final t = (motionController.value + phaseOffset) % 1.0;
        final scale = 0.8 + 0.3 * math.sin(t * 2 * math.pi);
        final opacity = 0.5 + 0.5 * math.sin(t * 2 * math.pi).abs();
        final rotation = t * 2 * math.pi;

        return Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              LucideIcons.sparkles,
              size: size,
              color: color.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

/// Soft ambient atmospheric background orb
class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

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
