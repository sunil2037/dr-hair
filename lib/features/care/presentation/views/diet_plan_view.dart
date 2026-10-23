import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';

/// 4. Diet & Nutrition Guide View
/// Tailored trichological nutrition plans, daily meal checklists, and hydration tracking.
class DietPlanView extends StatelessWidget {
  const DietPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final currentDay = state.currentDietDay;
        final currentDayMeals = currentDay < state.dietPlans.length
            ? state.dietPlans[currentDay]
            : <DietMeal>[];

        return CarePageScaffold(
          title: 'Nutrition & Diet Guide',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              careCard(
                backgroundColor: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFFFEDD5)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🥗 Clinical Follicular Nutrition',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hair follicles are metabolically demanding tissues. Supplying adequate keratin building amino acids, biotin, and ferritin prevents telogen shedding.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7C2D12),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Water Intake Tracker
              careCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F9FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.droplets,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hydration Intake',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${state.waterCups} of 8 glasses logged (~${(state.waterCups * 0.3).toStringAsFixed(1)}L)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.minusCircle),
                              color: AppColors.primary,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<CareCubit>().decrementWater();
                              },
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.plusCircle),
                              color: AppColors.primary,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<CareCubit>().incrementWater();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (state.waterCups / 8.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F9FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              careSectionHeader(
                title: 'DAILY ROTATING MEAL PLAN',
                subtitle: 'Tap each meal once completed',
              ),

              // Day selector tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(state.dietPlans.length, (idx) {
                    final isSelected = currentDay == idx;
                    final titles = [
                      'Day 1: High Protein',
                      'Day 2: Zinc & Folate',
                      'Day 3: Iron & Omega-3',
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(titles[idx.clamp(0, titles.length - 1)]),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            context.read<CareCubit>().selectDietDay(idx);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // Meals list
              ...currentDayMeals.asMap().entries.map((entry) {
                final mealIdx = entry.key;
                final meal = entry.value;
                final isDone = meal.isCompleted;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : AppColors.border,
                      width: isDone ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CareCubit>().toggleDietMeal(
                        currentDay,
                        mealIdx,
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    meal.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      meal.nutrients,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                meal.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDone
                                      ? AppColors.textSecondary
                                      : AppColors.primaryDark,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal.benefit,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),
              careSectionHeader(title: 'HAIR SUPERFOODS GLOSSARY'),
              careCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSuperfoodRow(
                      icon: '🫐',
                      title: 'Amla & Berries',
                      desc: 'Highest natural Vitamin C; drives scalp collagen.',
                    ),
                    const Divider(height: 20),
                    _buildSuperfoodRow(
                      icon: '🎃',
                      title: 'Pumpkin Seeds',
                      desc:
                          'Rich in phytosterols & zinc to suppress DHT naturally.',
                    ),
                    const Divider(height: 20),
                    _buildSuperfoodRow(
                      icon: '🥬',
                      title: 'Spinach & Methi',
                      desc:
                          'Bioavailable non-heme iron to lift ferritin levels.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildSuperfoodRow({
    required String icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
