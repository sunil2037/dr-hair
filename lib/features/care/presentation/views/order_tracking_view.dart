import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';

/// 6. Order Tracking View
/// Live prescription & clinical kit dispatch tracking, compounding status, and WhatsApp support.
class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final order = state.orders.isNotEmpty ? state.orders.first : null;

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
                          const Icon(
                            LucideIcons.truck,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Arrival: ${order.estimatedDelivery}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                careSectionHeader(title: 'DISPATCH TIMELINE'),

                // Delivery Stepper
                careCard(
                  child: Column(
                    children: [
                      _buildTimelineStep(
                        title: 'Order Confirmed & Payment Verified',
                        subtitle: 'Oct 20, 2026 · 10:14 AM',
                        isCompleted: order.currentStep >= 0,
                        isCurrent: order.currentStep == 0,
                      ),
                      _buildTimelineDivider(
                        isCompleted: order.currentStep >= 1,
                      ),
                      _buildTimelineStep(
                        title: 'Clinical Formulation Compounded',
                        subtitle: 'Pharmacist calibrated 5% topical booster',
                        isCompleted: order.currentStep >= 1,
                        isCurrent: order.currentStep == 1,
                      ),
                      _buildTimelineDivider(
                        isCompleted: order.currentStep >= 2,
                      ),
                      _buildTimelineStep(
                        title: 'Dispatched from Central Pharmacy',
                        subtitle: '${order.courierName} Hub · In transit',
                        isCompleted: order.currentStep >= 2,
                        isCurrent: order.currentStep == 2,
                      ),
                      _buildTimelineDivider(
                        isCompleted: order.currentStep >= 3,
                      ),
                      _buildTimelineStep(
                        title: 'Out for Delivery',
                        subtitle:
                            'Courier partner is on the way to your address',
                        isCompleted: order.currentStep >= 3,
                        isCurrent: order.currentStep == 3,
                      ),
                      _buildTimelineDivider(
                        isCompleted: order.currentStep >= 4,
                      ),
                      _buildTimelineStep(
                        title: 'Delivered',
                        subtitle: 'Expected by 2:00 PM',
                        isCompleted: order.currentStep >= 4,
                        isCurrent: order.currentStep == 4,
                        isLast: true,
                      ),
                    ],
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
                              ScaffoldMessenger.of(context).showSnackBar(
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

                // Order items breakdown
                careCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items in this shipment',
                        style: TextStyle(
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
                          const Text(
                            'Total Paid',
                            style: TextStyle(
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
                SizedBox(
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
                    label: const Text('Contact Support regarding this order'),
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
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isCurrent ? AppColors.primary : AppColors.border),
          ),
          child: Icon(
            isCompleted
                ? LucideIcons.check
                : (isCurrent ? LucideIcons.loader : LucideIcons.circle),
            size: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isCompleted || isCurrent
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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

  static Widget _buildTimelineDivider({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 22,
      color: isCompleted ? const Color(0xFF10B981) : AppColors.border,
      alignment: Alignment.centerLeft,
    );
  }
}
