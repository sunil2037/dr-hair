import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/add_photo_checkin_bottom_sheet.dart';
import '../widgets/care_widgets.dart';
import '../widgets/compare_photos_bottom_sheet.dart';

/// 2. Progress Tracking View
/// Hair progress journal with check-ins, follicle density ratings, and Before & After comparison bottom sheet.
class ProgressTrackingView extends StatelessWidget {
  const ProgressTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        return CarePageScaffold(
          title: 'Hair Progress Journal',
          actions: [
            IconButton(
              tooltip: 'Compare before and after',
              icon: const Icon(
                LucideIcons.splitSquareVertical,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () =>
                  ComparePhotosBottomSheet.show(context, checkIns: state.checkIns),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(LucideIcons.camera, size: 18),
            label: const Text(
              'Add Check-In',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => AddPhotoCheckInBottomSheet.show(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner Card
              careCard(
                backgroundColor: AppColors.primary5,
                border: Border.all(color: AppColors.primary100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Hair Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Verified by Dr.Hair Dermatological Protocol',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        careStatPill(
                          label: 'Total Check-ins',
                          value: '${state.checkIns.length} Photos',
                        ),
                        careStatPill(
                          label: 'Tracking Since',
                          value: state.checkIns.isNotEmpty
                              ? '${state.checkIns.last.date.month}/${state.checkIns.last.date.year}'
                              : 'Month 1',
                        ),
                        careStatPill(
                          label: 'Status',
                          value: 'Active Regrowth',
                          valueColor: const Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => ComparePhotosBottomSheet.show(
                              context,
                              checkIns: state.checkIns,
                            ),
                            icon: const Icon(
                              LucideIcons.splitSquareVertical,
                              size: 16,
                            ),
                            label: const Text('Compare Before/After'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              careSectionHeader(
                title: 'PHOTO TIMELINE',
                subtitle:
                    'Tap any photo to view full size or observe follicle density',
              ),

              if (state.checkIns.isEmpty)
                careCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.camera,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No progress check-ins yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the button below to take your first scalp photo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...state.checkIns.map((ci) {
                  return careCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with region tag & date & delete
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary5,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ci.scalpRegion,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${ci.date.day} ${careMonthName(ci.date.month)} ${ci.date.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Check-in?'),
                                    content: const Text(
                                      'Are you sure you want to remove this progress photo from your journal?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context
                                              .read<CareCubit>()
                                              .deleteProgressCheckIn(ci.id);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Main Photo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            onTap: () {
                              // View Full screen photo modal
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: buildCarePhotoWidget(
                                          ci.imagePath,
                                          height: 380,
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
                            },
                            child: buildCarePhotoWidget(ci.imagePath, height: 180),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ratings & Shedding pill row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ci.sheddingLevel == 'Low / Normal'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.activity,
                                    size: 12,
                                    color: ci.sheddingLevel == 'Low / Normal'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFEA580C),
                                  ),
                                  const SizedBox(width: 4),
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
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (s) => Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: s < ci.densityRating
                                      ? AppColors.starGold
                                      : AppColors.border,
                                ),
                              ),
                            ),
                          ],
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
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }
}
