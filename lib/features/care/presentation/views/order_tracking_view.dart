import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';
import '../../../../core/widgets/app_toast.dart';

/// 6. Order Tracking View
/// Live prescription & clinical kit dispatch tracking, compounding status, and WhatsApp support.
class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final order = state.orders.isNotEmpty ? state.orders.first : null;
        final isPreviewOrder =
            order?.status.startsWith('Preview only') ?? false;

        return CarePageScaffold(
          title: 'Orders & Deliveries',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order == null)
                careCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.packageOpen,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No active orders found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Orders placed in the shop will appear here for live tracking.',
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
              else ...[
                // Order Status Banner Card
                careCard(
                  backgroundColor: const Color(0xFFECFDF5),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.orderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                'Placed on ${order.orderDate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            isPreviewOrder ? LucideIcons.package : LucideIcons.truck,
                            size: 16,
                            color: isPreviewOrder
                                ? AppColors.primary
                                : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPreviewOrder
                                ? 'Preview saved locally · no delivery scheduled'
                                : 'Estimated Arrival: ${order.estimatedDelivery}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isPreviewOrder) ...[
                careSectionHeader(title: 'DISPATCH TIMELINE'),

                // Delivery Stepper with TweenAnimationBuilder
                careCard(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: order.currentStep.toDouble(),
                    ),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeInOutCubic,
                    builder: (context, animValue, _) {
                      final timelineSteps = [
                        (
                          title: 'Order Confirmed & Payment Verified',
                          subtitle: 'Oct 20, 2026 · 10:14 AM',
                        ),
                        (
                          title: 'Clinical Formulation Compounded',
                          subtitle: 'Pharmacist calibrated 5% topical booster',
                        ),
                        (
                          title: 'Dispatched from Central Pharmacy',
                          subtitle: '${order.courierName} Hub · In transit',
                        ),
                        (
                          title: 'Out for Delivery',
                          subtitle:
                              'Courier partner is on the way to your address',
                        ),
                        (title: 'Delivered', subtitle: 'Expected by 2:00 PM'),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Progress Summary Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.truck,
                                    size: 20,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Step ${(animValue.clamp(0, math.max(0, order.currentStep)) + 1).toInt()} of 5 · ${order.status}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Animated Timeline Steps
                          for (int i = 0; i < timelineSteps.length; i++) ...[
                            _buildTimelineStep(
                              title: timelineSteps[i].title,
                              subtitle: timelineSteps[i].subtitle,
                              isCompleted:
                                  animValue >= i + 1 ||
                                  (i < order.currentStep && animValue >= i),
                              isCurrent:
                                  i == order.currentStep && animValue >= i,
                              isReached: animValue >= i,
                            ),
                            if (i < timelineSteps.length - 1)
                              _buildTimelineDivider(
                                progress: animValue,
                                stepIndex: i,
                              ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                careSectionHeader(title: 'SHIPPING & ITEMS'),

                // Courier & AWB Card
                careCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.courierName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'AWB: ${order.trackingNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.copy,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Copy Tracking ID',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: order.trackingNumber),
                              );
                              HapticFeedback.lightImpact();
                              AppToast.show(context,
                                const SnackBar(
                                  content: Text(
                                    'Tracking number copied to clipboard!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                ] else
                  careCard(
                    backgroundColor: AppColors.primary5,
                    child: const Text(
                      'This is a local preview only. No payment was taken, the order was not sent to the shop, and there is no courier tracking yet.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),

                // Order items breakdown
                careCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPreviewOrder
                            ? 'Items in this preview'
                            : 'Items in this shipment',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.package,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  it,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPreviewOrder
                                ? 'Estimated total (not paid)'
                                : 'Total Paid',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Support button
                if (!isPreviewOrder) SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final uri = Uri.parse(
                        'https://wa.me/918058056789?text=Hi%20DrHair,%20I%20have%20an%20inquiry%20regarding%20my%20Order%20%23${order.orderId}',
                      );
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        debugPrint('Could not launch WhatsApp: $e');
                      }
                    },
                    icon: Image.asset(
                      'assets/icons/whatsapp.png',
                      height: 18,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.messageCircle,
                        size: 18,
                        color: Color(0xFF25D366),
                      ),
                    ),
                    label: const Text(
                      'Contact Support regarding this order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isReached,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isCurrent
                      ? AppColors.primary
                      : (isReached
                            ? AppColors.primary100
                            : const Color(0xFFF1F5F9))),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : (isCurrent ? AppColors.primary : AppColors.border),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              isCompleted
                  ? LucideIcons.check
                  : (isCurrent ? LucideIcons.loader : LucideIcons.circle),
              size: 13,
              color: (isCompleted || isCurrent)
                  ? Colors.white
                  : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCompleted || isCurrent
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: (isCompleted || isCurrent)
                      ? AppColors.secondaryDark
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildTimelineDivider({
    required double progress,
    required int stepIndex,
  }) {
    final fill = (progress - stepIndex).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(left: 10.75, top: 4, bottom: 4),
      width: 2.5,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        heightFactor: fill,
        alignment: Alignment.topCenter,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
