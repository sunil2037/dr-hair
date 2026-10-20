import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../shop/presentation/viewmodels/cart_cubit.dart';
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
  late final ValueNotifier<double> _homeScrollOffset;
  late final ValueNotifier<bool> _isBottomNavHidden;

  @override
  void initState() {
    super.initState();
    _homeScrollOffset = ValueNotifier<double>(0);
    _isBottomNavHidden = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _homeScrollOffset.dispose();
    _isBottomNavHidden.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_isBottomNavHidden.value) _isBottomNavHidden.value = false;
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int currentTab = widget.navigationShell.currentIndex;
    final String location = GoRouterState.of(context).matchedLocation;
    final bool isHomeTab = currentTab == 0 && location == RouteNames.mainShell;
    final bool isVideosTab = currentTab == 2 || location == RouteNames.videos;
    final PreferredSizeWidget appBar = isHomeTab
        ? PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: ValueListenableBuilder<double>(
              valueListenable: _homeScrollOffset,
              builder: (context, offset, child) => CustomAppBar(
                scrollProgress: (offset / 80.0).clamp(0.0, 1.0),
              ),
            ),
          )
        : const CustomAppBar();

    return Scaffold(
      backgroundColor: isVideosTab ? Colors.black : AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: isHomeTab,
      appBar: isVideosTab ? null : appBar,
      // Screen body naturally fills the available viewport above the bottom nav bar
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;

          if (!isVideosTab && notification is UserScrollNotification) {
            final direction = notification.direction;
            if (direction != ScrollDirection.idle) {
              final shouldHide = direction == ScrollDirection.reverse;
              if (_isBottomNavHidden.value != shouldHide) {
                _isBottomNavHidden.value = shouldHide;
              }
            }
          }

          if (isHomeTab && notification is ScrollUpdateNotification) {
            final double pixels = notification.metrics.pixels;
            final double nextOffset = pixels.clamp(0.0, 300.0).toDouble();
            if (nextOffset != _homeScrollOffset.value) {
              _homeScrollOffset.value = nextOffset;
            }
          }
          return false;
        },
        child: widget.navigationShell,
      ),
      // Dedicated dual-element bottom navigation bar
      // The nav widget applies its own bottom-only SafeArea. Wrapping it here
      // too adds the iOS top/status-bar inset above the bar and makes it tall.
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _isBottomNavHidden,
        builder: (context, isNavHidden, child) => BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) => RepaintBoundary(
            child: ShellBottomNavBar(
              currentIndex: widget.navigationShell.currentIndex,
              cartItemCount: cartState.itemCount,
              cartSubtotal: cartState.subtotal,
              isHidden: isNavHidden && !isVideosTab,
              showBackground: !isVideosTab,
              onTabSelected: _onTabSelected,
              onCartPressed: () => context.push(RouteNames.cart),
              onActionPressed: () => context.push(RouteNames.hairTest),
            ),
          ),
        ),
      ),
    );
  }
}
