import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/add_photo_checkin_bottom_sheet.dart';
import '../widgets/care_widgets.dart';

/// Progress Tracking View
/// Displays date-wise treatment photo check-in cards with 3 clinical angles
/// (Front, Top, Back) and an animated spring expand/shrink FAB in bottom center.
class ProgressTrackingView extends StatefulWidget {
  final bool autoOpenAddCheckIn;

  const ProgressTrackingView({super.key, this.autoOpenAddCheckIn = false});

  @override
  State<ProgressTrackingView> createState() => _ProgressTrackingViewState();
}

class _ProgressTrackingViewState extends State<ProgressTrackingView> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = true;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.autoOpenAddCheckIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AddPhotoCheckInBottomSheet.show(context);
      });
    }
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Shrink during active scrolling (both directions)
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    }

    // Only expand after scrolling has completely stopped
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });
  }

  void _showFullScreenPhoto(
    BuildContext context,
    String imagePath,
    String title,
  ) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildCarePhotoWidget(imagePath, height: 400),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.black.withValues(alpha: 0.88),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageCheckInBottomSheet(BuildContext context, ProgressCheckIn ci) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          24 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Progress Check-in',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ci.date.day} ${careMonthName(ci.date.month)} ${ci.date.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.helpCircle,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Are you sure you want to remove this progress photo from your treatment timeline? Or would you prefer to re-upload new photos?',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.primary5,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(sheetContext);
                  AddPhotoCheckInBottomSheet.show(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.uploadCloud,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Re-upload Progress Photos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Capture fresh Front, Top, or Back scalp photos',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteCheckInConfirmation(context, ci);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Check-in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Permanently remove this photo check-in',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCheckInConfirmation(
    BuildContext context,
    ProgressCheckIn checkIn,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Delete this progress check-in?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Its photos and notes will be removed from your treatment timeline on this device. This cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Keep check-in'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Delete check-in'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    context.read<CareCubit>().deleteProgressCheckIn(checkIn.id);
  }

  Widget _buildPhotoThumbnail({
    required BuildContext context,
    required String label,
    required String imagePath,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showFullScreenPhoto(context, imagePath, label),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  buildCarePhotoWidget(imagePath, height: 112),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        LucideIcons.maximize2,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAddButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      height: 50,
      width: _isExpanded ? 210 : 50,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.lightImpact();
            AddPhotoCheckInBottomSheet.show(context);
          },
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.camera, color: Colors.white, size: 22),
                  AnimatedCrossFade(
                    firstChild: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Add Progress Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                    firstCurve: Curves.easeInOutCubic,
                    secondCurve: Curves.easeInOutCubic,
                    sizeCurve: Curves.easeInOutCubic,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final sortedCheckIns = List<ProgressCheckIn>.from(state.checkIns)
          ..sort((a, b) => b.date.compareTo(a.date));

        return CarePageScaffold(
          title: 'Hair Progress Journal',
          scrollController: _scrollController,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _buildAnimatedAddButton(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              careCard(
                backgroundColor: AppColors.primary5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.lightbulb,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make comparisons easier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use similar lighting, distance, and angles each time. A monthly check-in can help you compare changes over time.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Sample timeline entries are demo data. New photos are saved on this device and are not reviewed by a clinician.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => AddPhotoCheckInBottomSheet.show(context),
                  icon: const Icon(LucideIcons.camera, size: 15),
                  label: const Text('Add check-in'),
                ),
              ),
              if (sortedCheckIns.isEmpty)
                careCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.primary5,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Treatment Check-ins Yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Log your first 3-angle progress photos (Front, Top & Back) to track your clinical treatment journey.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondaryDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () =>
                                AddPhotoCheckInBottomSheet.show(context),
                            icon: const Icon(LucideIcons.camera, size: 16),
                            label: const Text(
                              'Add First Check-in',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...sortedCheckIns.map((ci) {
                  return careCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date, region & delete action header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary5,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.calendar,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${ci.date.day} ${careMonthName(ci.date.month)} ${ci.date.year}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 0,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: const Icon(
                                  LucideIcons.moreVertical,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              onTap: () =>
                                  _showManageCheckInBottomSheet(context, ci),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 3 Angle Photos Row (Front, Top, Back)
                        Row(
                          children: [
                            _buildPhotoThumbnail(
                              context: context,
                              label: 'Front View',
                              imagePath: ci.effectiveFrontImage,
                            ),
                            const SizedBox(width: 8),
                            _buildPhotoThumbnail(
                              context: context,
                              label: 'Top / Crown',
                              imagePath: ci.effectiveTopImage,
                            ),
                            const SizedBox(width: 8),
                            _buildPhotoThumbnail(
                              context: context,
                              label: 'Back View',
                              imagePath: ci.effectiveBackImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Shedding Level indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: ci.sheddingLevel == 'Low / Normal'
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.activity,
                                size: 12,
                                color: ci.sheddingLevel == 'Low / Normal'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Shedding: ${ci.sheddingLevel}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ci.sheddingLevel == 'Low / Normal'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (ci.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            ci.notes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryDark,
                              height: 1.4,
                            ),
                          ),
                        ],

                        if (ci.doctorNote != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary5,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.stethoscope,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ci.doctorNote!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
