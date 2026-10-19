import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// A reusable, highly customizable category filter chip bar with smooth micro-motion,
/// haptic feedback, and optional counts or badge indicators.
class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double height;
  final bool enableHaptics;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.selectedColor = AppColors.primary,
    this.unselectedColor = Colors.white,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = AppColors.secondaryDark,
    this.height = 42.0,
    this.enableHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;
          return _FilterChipItem(
            label: categories[index],
            isSelected: isSelected,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            selectedTextColor: selectedTextColor,
            unselectedTextColor: unselectedTextColor,
            onTap: () {
              if (enableHaptics) {
                HapticFeedback.lightImpact();
              }
              onSelected(index);
            },
          );
        },
      ),
    );
  }
}

class _FilterChipItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  @override
  State<_FilterChipItem> createState() => _FilterChipItemState();
}

class _FilterChipItemState extends State<_FilterChipItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    final Duration duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 160);

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          splashColor: widget.selectedColor.withValues(alpha: 0.12),
          highlightColor: widget.selectedColor.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.selectedColor
                  : widget.unselectedColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isSelected
                    ? widget.selectedColor
                    : AppColors.border,
                width: 1.2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.selectedColor.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                color: widget.isSelected
                    ? widget.selectedTextColor
                    : widget.unselectedTextColor,
                letterSpacing: 0.1,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// A SliverPersistentHeaderDelegate that pins [CategoryFilterBar] at the top of a [NestedScrollView].
class SliverCategoryFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color backgroundColor;
  final double extent;

  const SliverCategoryFilterBarDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    this.backgroundColor = AppColors.background,
    this.extent = 54.0,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bool isPinned = shrinkOffset > 0 || overlapsContent;

    return Container(
      height: extent,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isPinned ? AppColors.border : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: CategoryFilterBar(
        categories: categories,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverCategoryFilterBarDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.categories != categories ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
