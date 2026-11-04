import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';

/// 6. Order Tracking View
/// Live prescription & clinical kit dispatch tracking, compounding status, and WhatsApp support.
class OrderTrackingView extends StatefulWidget {
  final String? initialOrderId;
  const OrderTrackingView({super.key, this.initialOrderId});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  int _selectedOrderIndex = 0;
  bool _isCancelling = false;
  bool _initialIndexSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CareCubit>().fetchPatientOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'shipped':
        return const Color(0xFF3B82F6);
      case 'preparing':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'refunded':
        return const Color(0xFFEF4444);
      case 'new':
      default:
        return AppColors.primary;
    }
  }

  Future<void> _handleCancelOrder(PatientOrder order) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CancelOrderBottomSheet(order: order),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      HapticFeedback.mediumImpact();
      final success = await context.read<CareCubit>().cancelOrder(order.orderId);
      if (!mounted) return;
      setState(() => _isCancelling = false);
      if (success) {
        final orderCode = order.orderId.length > 8
            ? order.orderId.substring(0, 8).toUpperCase()
            : order.orderId;
        AppToast.show(
          context,
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order #$orderCode cancelled. Full refund will be credited in 3–5 days.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        AppToast.show(
          context,
          const SnackBar(
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to cancel order. Please contact clinic support.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        if (!_initialIndexSet && widget.initialOrderId != null && state.orders.isNotEmpty) {
          final targetIdx = state.orders.indexWhere((o) => o.orderId == widget.initialOrderId);
          if (targetIdx != -1) {
            _selectedOrderIndex = targetIdx;
            _initialIndexSet = true;
          }
        }
        final safeIndex = state.orders.isEmpty
            ? 0
            : _selectedOrderIndex.clamp(0, state.orders.length - 1);
        final order = state.orders.isNotEmpty ? state.orders[safeIndex] : null;
        final isPreviewOrder =
            order?.status.startsWith('Preview only') ?? false;
        final isCancellable = order != null &&
            !isPreviewOrder &&
            (order.status == 'New' || order.status == 'Preparing');

        return CarePageScaffold(
          title: 'Track Order',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.orders.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(state.orders.length, (idx) {
                      final ord = state.orders[idx];
                      final isSelected = idx == safeIndex;
                      final shortId = ord.orderId.length > 12
                          ? '${ord.orderId.substring(0, 8)}...'
                          : ord.orderId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 12),
                        child: ChoiceChip(
                          label: Text('#$shortId (${ord.status})'),
                          selected: isSelected,
                          selectedColor: AppColors.primary100,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedOrderIndex = idx);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
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
                  backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.08),
                  border: Border.all(
                    color: _getStatusColor(order.status).withValues(alpha: 0.3),
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
                              color: _getStatusColor(order.status),
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

                // Cancel Order button (if status is New or Preparing)
                if (isCancellable) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isCancelling
                          ? null
                          : () => _handleCancelOrder(order),
                      icon: _isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(LucideIcons.ban, size: 18),
                      label: Text(
                        _isCancelling ? 'Cancelling...' : 'Cancel Order & Release Items',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Support button
                if (!isPreviewOrder) ...[
                  const SizedBox(height: 12),
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

/// Dedicated, clinical bottom sheet providing empathetic order cancellation,
/// clear policy explanation, and feedback reasons for the Dr. Hair care team.
class _CancelOrderBottomSheet extends StatefulWidget {
  final PatientOrder order;

  const _CancelOrderBottomSheet({required this.order});

  @override
  State<_CancelOrderBottomSheet> createState() =>
      _CancelOrderBottomSheetState();
}

class _CancelOrderBottomSheetState extends State<_CancelOrderBottomSheet> {
  String? _selectedReason = 'Ordered by mistake';

  static const List<String> _reasons = [
    'Ordered by mistake',
    'Need to change delivery address',
    'Want to re-consult doctor first',
    'Delivery timeframe too long',
    'Found another alternative',
    'Other reason',
  ];

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderCode = order.orderId.length > 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row with Red Badge & Close Button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.packageX,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancel Care Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order #$orderCode · ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: AppColors.textMuted,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Clinical Policy Notice Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'What happens when you cancel?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBullet(
                    'Personalized compounding & dispensary dispatch will be halted immediately.',
                  ),
                  const SizedBox(height: 6),
                  _buildBullet(
                    'Reserved prescription stock will be returned to clinic inventory.',
                  ),
                  const SizedBox(height: 6),
                  _buildBullet(
                    'If already paid online, 100% full refund is credited to your original payment method in 3–5 business days.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Reason for Cancellation
            const Text(
              'Reason for cancellation (optional)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedReason = reason);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Keep Order',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context, false),
                    height: 48,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Cancel Order',
                    variant: AppButtonVariant.filled,
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    onPressed: () => Navigator.pop(context, true),
                    height: 48,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, right: 8),
          child: Icon(
            LucideIcons.check,
            size: 13,
            color: Color(0xFFD97706),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF78350F),
            ),
          ),
        ),
      ],
    );
  }
}
