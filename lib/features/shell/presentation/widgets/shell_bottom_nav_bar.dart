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
  final bool isHidden;
  final bool showBackground;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCartPressed;
  final int cartItemCount;
  final int? cartSubtotal;
  final VoidCallback? onActionPressed;
  final bool isTestCompleted;

  const ShellBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isHidden = false,
    this.showBackground = true,
    required this.onTabSelected,
    this.onCartPressed,
    this.cartItemCount = 0,
    this.cartSubtotal,
    this.onActionPressed,
    this.isTestCompleted = false,
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
      if (widget.isTestCompleted) {
        context.push(RouteNames.products);
      } else {
        context.push(RouteNames.hairTest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disableMotion = MediaQuery.disableAnimationsOf(context);
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final Duration motionDuration = disableMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final double barHeight = isIOS ? 53 : 55;
    final double actionSize = isIOS ? 53 : 55;

    final int? currentPillIndex = _getPillIndex(widget.currentIndex);
    if (currentPillIndex != null) {
      _lastPillIndex = currentPillIndex;
    }
    final int targetSlotIndex = currentPillIndex ?? _lastPillIndex;
    final bool isPillIndicatorVisible = currentPillIndex != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.showBackground)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: motionDuration,
                curve: Curves.easeInOutCubic,
                offset: Offset(0, widget.isHidden ? 1 : 0),
                child: AnimatedOpacity(
                  duration: motionDuration,
                  curve: Curves.easeInOutCubic,
                  opacity: widget.isHidden ? 0 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,

                        colors: [
                          Colors.white.withValues(alpha: .02),
                          Color(0xF2FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          minimum: EdgeInsets.only(bottom: isIOS ? 0 : 10, top: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Floating Cart Summary Bar
              if (widget.cartItemCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: IgnorePointer(
                    ignoring: widget.isHidden,
                    child: AnimatedSlide(
                      duration: motionDuration,
                      curve: Curves.easeOutCubic,
                      offset: Offset(0, widget.isHidden ? 1.25 : 0),
                      child: AnimatedOpacity(
                        duration: motionDuration,
                        curve: Curves.easeOutCubic,
                        opacity: widget.isHidden ? 0 : 1,
                        child: _buildCartSummaryBar(),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(key: ValueKey('cart-summary-hidden')),

              // 2. Navigation Row (Pill + Standalone Action Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: isIOS ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Floating Pill with Navigation Tabs & Sliding Capsule Indicator
                    Expanded(
                      child: IgnorePointer(
                        ignoring: widget.isHidden,
                        child: AnimatedSlide(
                          duration: motionDuration,
                          curve: Curves.easeInOutCubic,
                          offset: Offset(0, widget.isHidden ? 1.5 : 0),
                          child: AnimatedOpacity(
                            duration: motionDuration,
                            curve: Curves.easeInOutCubic,
                            opacity: widget.isHidden ? 0 : 1,
                            child: Container(
                              width: double.infinity,
                              height: barHeight,
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
                                  final double slotWidth =
                                      constraints.maxWidth / 4;
                                  final double indicatorLeft =
                                      (targetSlotIndex * slotWidth) + 2;

                                  return Stack(
                                    clipBehavior: Clip.none,
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
                                          opacity: isPillIndicatorVisible
                                              ? 1.0
                                              : 0.0,
                                          curve: Curves.easeOutCubic,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F3F5),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.025),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildTabItem(
                                              index: 0,
                                              icon: LucideIcons.home,
                                              label: 'Home',
                                              motionDuration: motionDuration,
                                            ),
                                            _buildTabItem(
                                              index: 1,
                                              icon: LucideIcons.listChecks,
                                              label: 'Reviews',
                                              motionDuration: motionDuration,
                                            ),
                                            _buildTabItem(
                                              index: 2,
                                              icon: LucideIcons.circlePlay,
                                              label: 'Videos',
                                              motionDuration: motionDuration,
                                            ),
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
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Standalone Circular Action Button
                    IgnorePointer(
                      ignoring: widget.isHidden,
                      child: AnimatedSlide(
                        duration: motionDuration,
                        curve: Curves.easeInOutCubic,
                        offset: Offset(widget.isHidden ? 1.5 : 0, 0),
                        child: AnimatedOpacity(
                          duration: motionDuration,
                          curve: Curves.easeInOutCubic,
                          opacity: widget.isHidden ? 0 : 1,
                          child: _buildCircularActionButton(
                            isSelected: false,
                            motionDuration: motionDuration,
                            size: actionSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartSummaryBar() {
    final count = widget.cartItemCount;
    final subtotal = widget.cartSubtotal;

    return Semantics(
      button: true,
      label:
          'View cart, $count ${count == 1 ? 'item' : 'items'}${subtotal != null && subtotal > 0 ? ', total ₹$subtotal' : ''}',
      child: Material(
        key: const ValueKey('cart-summary'),
        color: AppColors.primary5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary100),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onCartPressed?.call();
          },
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.shoppingBag,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtotal != null && subtotal > 0
                              ? '$count ${count == 1 ? 'item' : 'items'} · ₹$subtotal'
                              : '$count ${count == 1 ? 'item' : 'items'} in cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Tap to review & checkout',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.secondaryDark,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'View Cart',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
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
    required double size,
  }) {
    final bool isCompleted = widget.isTestCompleted;
    final String label = isCompleted ? 'Products' : 'AI Hair Analysis';

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
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
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeBg,
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: iconAngle,
                      child: Transform.scale(
                        scale: iconScale,
                        child: isCompleted
                            ? const Icon(
                                LucideIcons.pill,
                                color: Colors.white,
                                size: 24,
                              )
                            : Image.asset(
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
