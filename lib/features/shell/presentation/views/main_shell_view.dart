import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../widgets/shell_bottom_nav_bar.dart';

/// The root shell view that wraps bottom tabs inside GoRouter's [StatefulNavigationShell].
/// Uses native Scaffold layout to cleanly separate screen content and the bottom navigation bar.
class MainShellView extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellView({super.key, required this.navigationShell});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  double _homeScrollOffset = 0.0;

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int currentTab = widget.navigationShell.currentIndex;
    final bool isHomeTab = currentTab == 0;
    // Transition from transparent (0.0) to solid white (1.0) over the first 80px of scrolling
    final double scrollProgress =
        isHomeTab ? (_homeScrollOffset / 80.0).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: isHomeTab,
      appBar: CustomAppBar(
        scrollProgress: scrollProgress,
      ),
      // Screen body naturally fills the available viewport above the bottom nav bar
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical && isHomeTab) {
            final double pixels = notification.metrics.pixels;
            if (pixels != _homeScrollOffset) {
              setState(() {
                _homeScrollOffset = pixels.clamp(0.0, 300.0);
              });
            }
          }
          return false;
        },
        child: widget.navigationShell,
      ),
      // Dedicated dual-element bottom navigation bar
      bottomNavigationBar: SafeArea(
        child: ShellBottomNavBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTabSelected: _onTabSelected,
          onActionPressed: () => context.push(RouteNames.hairTest),
        ),
      ),
    );
  }
}
