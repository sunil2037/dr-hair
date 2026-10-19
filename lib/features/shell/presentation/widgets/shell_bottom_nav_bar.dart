import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';

/// Modern bottom navigation bar inspired by the dual-element design:
/// - A sleek floating pill with a fluid sliding capsule indicator for active tabs.
/// - A standalone circular action button on the right that navigates to a dedicated full-screen view.
class ShellBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCartPressed;
  final VoidCallback? onActionPressed;

  const ShellBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onCartPressed,
    this.onActionPressed,
  });

  @override
  State<ShellBottomNavBar> createState() => _ShellBottomNavBarState();
}

class _ShellBottomNavBarState extends State<ShellBottomNavBar> {
  int? _pressedTabIndex;
  bool _isActionPressed = false;
  int _lastPillIndex = 0;

  int? _getPillIndex(int tabIndex) {
    if (tabIndex >= 0 && tabIndex <= 3) {
      return tabIndex;
    }
    return null;
  }

  void _handleTabTap(int index) {
    HapticFeedback.selectionClick();
    widget.onTabSelected(index);
  }

  void _handleActionTap() {
    HapticFeedback.mediumImpact();
    if (widget.onActionPressed != null) {
      widget.onActionPressed!();
    } else {
      context.push(RouteNames.hairTest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disableMotion = MediaQuery.disableAnimationsOf(context);
    final Duration motionDuration = disableMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    final int? currentPillIndex = _getPillIndex(widget.currentIndex);
    if (currentPillIndex != null) {
      _lastPillIndex = currentPillIndex;
    }
    final int targetSlotIndex = currentPillIndex ?? _lastPillIndex;
    final bool isPillIndicatorVisible = currentPillIndex != null;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 12, top: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Floating Pill with Navigation Tabs & Sliding Capsule Indicator
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double slotWidth = constraints.maxWidth / 4;
                      final double indicatorLeft =
                          (targetSlotIndex * slotWidth) + 2;

                      return Stack(
                        children: [
                          // Fluid Sliding Capsule Indicator
                          AnimatedPositioned(
                            duration: motionDuration,
                            curve: Curves.easeOutCubic,
                            left: indicatorLeft,
                            top: 2,
                            bottom: 2,
                            width: slotWidth - 4,
                            child: AnimatedOpacity(
                              duration: motionDuration,
                              opacity: isPillIndicatorVisible ? 1.0 : 0.0,
                              curve: Curves.easeOutCubic,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F5),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.025,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Tab Items Row
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Home (index 0)
                                _buildTabItem(
                                  index: 0,
                                  icon: LucideIcons.home,
                                  label: 'Home',
                                  motionDuration: motionDuration,
                                ),

                                // Reviews (index 1)
                                _buildTabItem(
                                  index: 1,
                                  icon: LucideIcons.listChecks,
                                  label: 'Reviews',
                                  motionDuration: motionDuration,
                                ),

                                // Videos (index 2)
                                _buildTabItem(
                                  index: 2,
                                  icon: LucideIcons.circlePlay,
                                  label: 'Videos',
                                  motionDuration: motionDuration,
                                ),

                                // Profile (index 3)
                                _buildTabItem(
                                  index: 3,
                                  icon: LucideIcons.userRound,
                                  label: 'Profile',
                                  motionDuration: motionDuration,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Standalone Circular Action Button (navigates to standalone screen)
              _buildCircularActionButton(
                isSelected: false,
                motionDuration: motionDuration,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required Duration motionDuration,
  }) {
    final bool isSelected = widget.currentIndex == index;
    final bool isPressed = _pressedTabIndex == index;

    final Color activeIconColor = AppColors.primary800;
    final Color inactiveIconColor = const Color(0xFF64748B);

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        selected: isSelected,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTapDown: (_) => setState(() => _pressedTabIndex = index),
            onTapUp: (_) => setState(() => _pressedTabIndex = null),
            onTapCancel: () => setState(() => _pressedTabIndex = null),
            onTap: () => _handleTabTap(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox.expand(
              child: Center(
                child: AnimatedScale(
                  scale: isPressed ? 0.92 : 1.0,
                  duration: motionDuration,
                  curve: Curves.easeOutCubic,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.0 : 0.9,
                        duration: motionDuration,
                        curve: Curves.easeOutBack,
                        child: Icon(
                          icon,
                          color: isSelected
                              ? activeIconColor
                              : inactiveIconColor,
                          size: 22,
                        ),
                      ),
                      // const SizedBox(height: 3),
                      // AnimatedDefaultTextStyle(
                      //   duration: motionDuration,
                      //   curve: Curves.easeOutCubic,
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     fontFamily: 'Inter',
                      //     fontSize: 8,
                      //     fontWeight: isSelected
                      //         ? FontWeight.w700
                      //         : FontWeight.w500,
                      //     color: isSelected
                      //         ? activeTextColor
                      //         : inactiveTextColor,
                      //     letterSpacing: 0.1,
                      //   ),
                      //   child: Text(label, textAlign: TextAlign.center),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionButton({
    bool isSelected = false,
    required Duration motionDuration,
  }) {
    return Semantics(
      button: true,
      label: 'AI Hair Analysis',
      selected: isSelected,
      excludeSemantics: true,
      child: Tooltip(
        message: 'AI Hair Analysis',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => setState(() => _isActionPressed = true),
          onTapUp: (_) => setState(() => _isActionPressed = false),
          onTapCancel: () => setState(() => _isActionPressed = false),
          onTap: _handleActionTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _isActionPressed ? 1.0 : 0.0),
            duration: motionDuration,
            curve: Curves.easeOutCubic,
            builder: (context, pressProgress, child) {
              final double baseScale = isSelected ? 1.04 : 1.0;
              final double scale = baseScale - (0.12 * pressProgress);
              final double iconScale =
                  (isSelected ? 1.0 : 0.92) - (0.05 * pressProgress);
              final double iconAngle = -0.05 * pressProgress;

              final Color activeBg = AppColors.primary;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeBg,
                    boxShadow: [
                      BoxShadow(
                        color: activeBg.withValues(
                          alpha: isSelected
                              ? (0.35 + 0.15 * pressProgress)
                              : (0.25 + 0.15 * pressProgress),
                        ),
                        blurRadius: 10 + 6 * pressProgress,
                        offset: Offset(0, 3 + 2 * (1.0 - pressProgress)),
                        spreadRadius: isSelected
                            ? 1.5
                            : 0.5 * (1.0 - pressProgress),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: iconAngle,
                      child: Transform.scale(
                        scale: iconScale,
                        child: Image.asset(
                          "assets/icons/LampIcon.png",
                          height: 26,
                          width: 26,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                LucideIcons.sparkles,
                                color: Colors.white,
                                size: 24,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
