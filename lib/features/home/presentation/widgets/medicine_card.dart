import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_cached_image.dart';

enum MedicineCategory {
  dermatologist,
  ayurveda;

  String get displayName => switch (this) {
    MedicineCategory.dermatologist => 'Dermatologist',
    MedicineCategory.ayurveda => 'Ayurveda',
  };
}

class MedicineCard extends StatelessWidget {
  final String title;
  final String desc;
  final String price;
  final String imageUrl;
  final MedicineCategory category;
  final double rating;
  final VoidCallback? onTap;
  final double width;
  final bool showAddToCart;

  const MedicineCard({
    super.key,
    required this.title,
    required this.desc,
    required this.price,
    required this.imageUrl,
    this.category = MedicineCategory.dermatologist,
    this.rating = 4.8,
    this.onTap,
    this.width = 220,
    this.showAddToCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAyurveda = category == MedicineCategory.ayurveda;

    return Semantics(
      label:
          '$title, ${category.displayName}, price $price, rated ${rating.toStringAsFixed(1)} out of 5 stars',
      button: true,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image with Category Badge (Dermatologist vs Ayurveda)
                  Stack(
                    children: [
                      CustomCachedImage(
                        imageUrl: imageUrl,
                        height: 140,
                        width: double.infinity,
                        borderRadius: 16,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isAyurveda ? LucideIcons.leaf : LucideIcons.pill,
                            color: isAyurveda
                                ? AppColors.success
                                : AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),

                      // Category Badge (Dermatologist / Ayurveda)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAyurveda
                                ? Colors.white.withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAyurveda
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAyurveda
                                    ? LucideIcons.leaf
                                    : LucideIcons.stethoscope,
                                size: 11,
                                color: isAyurveda
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isAyurveda
                                      ? AppColors.success
                                      : AppColors.primary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Description
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryDark,
                            ),
                          ),

                          const Spacer(),

                          // Bottom Section: Price + Clinical Rating/Details (NO add to cart button)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),

                              if (showAddToCart)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.plus,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.star,
                                      size: 13,
                                      color: AppColors.starGold,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      LucideIcons.chevronRight,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
