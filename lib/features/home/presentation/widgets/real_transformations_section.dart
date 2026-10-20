import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_cached_image.dart';

/// Reusable Before & After Transformation Card
class RealTransformationCard extends StatelessWidget {
  final String caseId;
  final String durationText;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final VoidCallback? onTap;

  const RealTransformationCard({
    super.key,
    this.caseId = 'CASE ID: #4820',
    this.durationText = '3 Months Result',
    this.beforeImageUrl =
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600',
    this.afterImageUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600',
    this.beforeLabel = 'BEFORE',
    this.afterLabel = 'AFTER',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Before Image
                Expanded(
                  child: Stack(
                    children: [
                      CustomCachedImage(
                        imageUrl: beforeImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        customBorderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            beforeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                // After Image
                Expanded(
                  child: Stack(
                    children: [
                      CustomCachedImage(
                        imageUrl: afterImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        customBorderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            afterLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    caseId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      durationText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Section displaying the header title and the transformation card
class RealTransformationsSection extends StatelessWidget {
  final String title;
  final String caseId;
  final String durationText;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const RealTransformationsSection({
    super.key,
    this.title = 'Real Transformations',
    this.caseId = 'CASE ID: #4820',
    this.durationText = '3 Months Result',
    this.beforeImageUrl =
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600',
    this.afterImageUrl =
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600',
    this.beforeLabel = 'BEFORE',
    this.afterLabel = 'AFTER',
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          RealTransformationCard(
            caseId: caseId,
            durationText: durationText,
            beforeImageUrl: beforeImageUrl,
            afterImageUrl: afterImageUrl,
            beforeLabel: beforeLabel,
            afterLabel: afterLabel,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
