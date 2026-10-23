import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/care_models.dart';
import 'care_widgets.dart';

/// Interactive reusable bottom sheet for comparing before & after hair progress check-in photos.
class ComparePhotosBottomSheet extends StatefulWidget {
  final List<ProgressCheckIn> checkIns;
  final ProgressCheckIn? initialBaseline;
  final ProgressCheckIn? initialLatest;

  const ComparePhotosBottomSheet({
    super.key,
    required this.checkIns,
    this.initialBaseline,
    this.initialLatest,
  });

  /// Displays the comparison bottom sheet.
  /// Validates that at least 2 check-ins exist before opening.
  static Future<void> show(
    BuildContext context, {
    required List<ProgressCheckIn> checkIns,
    ProgressCheckIn? initialBaseline,
    ProgressCheckIn? initialLatest,
  }) async {
    if (checkIns.length < 2) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primaryDark,
          content: const Row(
            children: [
              Icon(LucideIcons.info, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Log at least 2 photos to compare before and after progress!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ComparePhotosBottomSheet(
        checkIns: checkIns,
        initialBaseline: initialBaseline,
        initialLatest: initialLatest,
      ),
    );
  }

  @override
  State<ComparePhotosBottomSheet> createState() =>
      _ComparePhotosBottomSheetState();
}

class _ComparePhotosBottomSheetState extends State<ComparePhotosBottomSheet> {
  late ProgressCheckIn _baseline;
  late ProgressCheckIn _latest;
  int _comparisonViewMode = 0; // 0: Side-by-Side, 1: Split Slider
  double _splitPosition = 0.5; // For slider mode (0.0 to 1.0)

  @override
  void initState() {
    super.initState();
    // Default baseline is the earliest (last in descending list), latest is the most recent (first)
    _baseline = widget.initialBaseline ?? widget.checkIns.last;
    _latest = widget.initialLatest ?? widget.checkIns.first;
  }

  void _showFullScreenPhoto(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: buildCarePhotoWidget(imagePath, height: 420),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final daysDifference = _latest.date.difference(_baseline.date).inDays.abs();
    final densityDelta = _latest.densityRating - _baseline.densityRating;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hair Regrowth Comparison',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Day 1 Baseline vs Check-In (${daysDifference == 0 ? "Same day" : "$daysDifference days progress"})',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.background,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.x, size: 18, color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // View Mode Selector (Side-by-Side vs Interactive Slider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      index: 0,
                      icon: LucideIcons.columns2,
                      label: 'Side-by-Side',
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      index: 1,
                      icon: LucideIcons.splitSquareVertical,
                      label: 'Interactive Wipe',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Comparison Content (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Selection Chips (if more than 2 photos exist)
                  if (widget.checkIns.length > 2) ...[
                    _buildCheckInSelectors(),
                    const SizedBox(height: 14),
                  ],

                  // Visual Comparison View
                  if (_comparisonViewMode == 0)
                    _buildSideBySideView()
                  else
                    _buildInteractiveSliderView(),

                  const SizedBox(height: 18),

                  // Clinical Metrics Card
                  careCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.primary5,
                    border: Border.all(color: AppColors.primary100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.activity, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Clinical Follicle Response',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            careStatPill(
                              label: 'Treatment Span',
                              value: '$daysDifference Days',
                            ),
                            careStatPill(
                              label: 'Follicle Density',
                              value: densityDelta > 0
                                  ? '+$densityDelta Rating ★'
                                  : (densityDelta == 0 ? 'Consistent ★' : '$densityDelta Rating'),
                              valueColor: densityDelta >= 0
                                  ? const Color(0xFF059669)
                                  : AppColors.danger,
                            ),
                            careStatPill(
                              label: 'Shedding Trend',
                              value: _latest.sheddingLevel == 'Low / Normal'
                                  ? 'Optimal'
                                  : _latest.sheddingLevel,
                              valueColor: _latest.sheddingLevel == 'Low / Normal'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEA580C),
                            ),
                          ],
                        ),
                        if (_latest.doctorNote != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.primary100),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.stethoscope,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Doctor Note: ${_latest.doctorNote!}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Close Comparison',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _comparisonViewMode == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _comparisonViewMode = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        careSectionHeader(
          title: 'SELECT PHOTO CHECK-INS',
          subtitle: 'Compare any milestone photo against your baseline',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: widget.checkIns.map((ci) {
              final isBaseline = ci.id == _baseline.id;
              final isLatest = ci.id == _latest.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: isBaseline
                      ? const Icon(LucideIcons.history, size: 14, color: AppColors.primary)
                      : (isLatest
                          ? const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF059669))
                          : null),
                  label: Text(
                    '${ci.date.day} ${careMonthName(ci.date.month)} ${isBaseline ? "(Before)" : (isLatest ? "(After)" : "")}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isBaseline || isLatest ? FontWeight.w700 : FontWeight.w500,
                      color: isBaseline
                          ? AppColors.primary
                          : (isLatest ? const Color(0xFF059669) : AppColors.textSecondary),
                    ),
                  ),
                  selected: isBaseline || isLatest,
                  selectedColor: isBaseline ? AppColors.primary5 : const Color(0xFFECFDF5),
                  side: BorderSide(
                    color: isBaseline
                        ? AppColors.primary
                        : (isLatest ? const Color(0xFF10B981) : AppColors.border),
                  ),
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (!isBaseline) {
                        _latest = ci;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySideView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baseline Column
        Expanded(
          child: _buildPhotoColumn(
            checkIn: _baseline,
            badgeLabel: 'BASELINE',
            badgeBg: AppColors.primary5,
            badgeColor: AppColors.primary,
            isBaseline: true,
          ),
        ),
        const SizedBox(width: 12),
        // Latest Column
        Expanded(
          child: _buildPhotoColumn(
            checkIn: _latest,
            badgeLabel: 'PROGRESS',
            badgeBg: const Color(0xFFECFDF5),
            badgeColor: const Color(0xFF059669),
            isBaseline: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoColumn({
    required ProgressCheckIn checkIn,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeColor,
    required bool isBaseline,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with full screen view button
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showFullScreenPhoto(
                    context,
                    checkIn.imagePath,
                    isBaseline ? 'Baseline Photo' : 'Latest Check-in',
                  ),
                  child: buildCarePhotoWidget(checkIn.imagePath, height: 160),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.maximize2, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Date & Region
          Text(
            '${checkIn.date.day} ${careMonthName(checkIn.date.month)} ${checkIn.date.year}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            checkIn.scalpRegion,
            style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryDark),
          ),
          const SizedBox(height: 6),

          // Stars & Shedding
          Row(
            children: [
              ...List.generate(
                5,
                (s) => Icon(
                  LucideIcons.star,
                  size: 11,
                  color: s < checkIn.densityRating
                      ? AppColors.starGold
                      : AppColors.border,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: checkIn.sheddingLevel == 'Low / Normal'
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  checkIn.sheddingLevel,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: checkIn.sheddingLevel == 'Low / Normal'
                        ? const Color(0xFF059669)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSliderView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 280.0;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _splitPosition =
                      (_splitPosition + (details.delta.dx / width)).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                children: [
                  // Under layer: Baseline (Before)
                  SizedBox(
                    width: width,
                    height: height,
                    child: buildCarePhotoWidget(_baseline.imagePath, height: height),
                  ),

                  // Top layer: Latest (After) clipped horizontally
                  ClipRect(
                    clipper: _SplitViewClipper(splitFactor: _splitPosition),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: buildCarePhotoWidget(_latest.imagePath, height: height),
                    ),
                  ),

                  // Badges: BEFORE (Left) & AFTER (Right)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BEFORE (${_baseline.date.day}/${_baseline.date.month})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AFTER (${_latest.date.day}/${_latest.date.month})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // Vertical divider line with draggable circle handle
                  Positioned(
                    left: width * _splitPosition - 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.chevronsLeftRight,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Drag Hint
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Drag left / right to reveal changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplitViewClipper extends CustomClipper<Rect> {
  final double splitFactor;

  _SplitViewClipper({required this.splitFactor});

  @override
  Rect getClip(Size size) {
    // Only show the right portion (from split position to the end)
    return Rect.fromLTRB(size.width * splitFactor, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _SplitViewClipper oldClipper) {
    return oldClipper.splitFactor != splitFactor;
  }
}
