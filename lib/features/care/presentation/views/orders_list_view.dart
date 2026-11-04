import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/models/care_models.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';

enum OrderCategory { pending, confirmed, cancelled }

/// Order List View
/// Shows categorized patient orders in 3 tabs: Pending, Confirmed, and Cancelled.
/// Tapping an order card navigates to the detailed live OrderTrackingView.
class OrdersListView extends StatefulWidget {
  const OrdersListView({super.key});

  @override
  State<OrdersListView> createState() => _OrdersListViewState();
}

class _OrdersListViewState extends State<OrdersListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      await context.read<CareCubit>().fetchPatientOrders();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  OrderCategory _categorizeOrder(CareOrder order) {
    final status = order.status.trim().toLowerCase();
    if (status == 'cancelled' ||
        status == 'refunded' ||
        status.contains('return') ||
        status.contains('cancel')) {
      return OrderCategory.cancelled;
    }
    if (status == 'shipped' ||
        status == 'delivered' ||
        status == 'completed' ||
        status == 'confirmed') {
      return OrderCategory.confirmed;
    }
    return OrderCategory.pending;
  }

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Recent order';
    try {
      final dt = DateTime.parse(rawDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'shipped':
        return const Color(0xFF2563EB);
      case 'preparing':
      case 'formulating':
        return const Color(0xFFD97706);
      case 'cancelled':
      case 'refunded':
        return const Color(0xFFDC2626);
      case 'new':
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFECFDF5);
      case 'shipped':
        return const Color(0xFFEFF6FF);
      case 'preparing':
      case 'formulating':
        return const Color(0xFFFFFBEB);
      case 'cancelled':
      case 'refunded':
        return const Color(0xFFFEF2F2);
      case 'new':
      default:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return LucideIcons.circleCheck;
      case 'shipped':
        return LucideIcons.truck;
      case 'preparing':
      case 'formulating':
        return LucideIcons.flaskConical;
      case 'cancelled':
      case 'refunded':
        return LucideIcons.circleX;
      case 'new':
      default:
        return LucideIcons.packageOpen;
    }
  }

  void _openOrderDetails(CareOrder order) {
    context.push(RouteNames.orderTracking, extra: order.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final allOrders = state.orders;
        final pendingOrders = allOrders
            .where((o) => _categorizeOrder(o) == OrderCategory.pending)
            .toList();
        final confirmedOrders = allOrders
            .where((o) => _categorizeOrder(o) == OrderCategory.confirmed)
            .toList();
        final cancelledOrders = allOrders
            .where((o) => _categorizeOrder(o) == OrderCategory.cancelled)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: false,
                  elevation: innerBoxIsScrolled ? 1 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  expandedHeight: 180.0,
                  leading: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.primaryDark,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  centerTitle: true,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                    child: const Text(
                      '',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              LucideIcons.refreshCw,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                      onPressed: _isRefreshing ? null : _loadOrders,
                      tooltip: 'Refresh Orders',
                    ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'My Orders',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  allOrders.isEmpty
                                      ? 'Track personalized kits & care shipments'
                                      : '${allOrders.length} order${allOrders.length == 1 ? '' : 's'} placed with clinic',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary5,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              LucideIcons.packageCheck,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _buildSlidingTabBar(
                        pendingCount: pendingOrders.length,
                        confirmedCount: confirmedOrders.length,
                        cancelledCount: cancelledOrders.length,
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildOrdersTabList(
                  orders: pendingOrders,
                  emptyTitle: 'No Pending Orders',
                  emptySubtitle:
                      'All your new and preparing orders will show up here.',
                  category: OrderCategory.pending,
                ),
                _buildOrdersTabList(
                  orders: confirmedOrders,
                  emptyTitle: 'No Confirmed Orders',
                  emptySubtitle: 'Orders that have been dispatched or delivered will appear here.',
                  category: OrderCategory.confirmed,
                ),
                _buildOrdersTabList(
                  orders: cancelledOrders,
                  emptyTitle: 'No Cancelled Orders',
                  emptySubtitle:
                      'You do not have any cancelled or refunded orders.',
                  category: OrderCategory.cancelled,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SLIDING TAB BAR (Exact sleek sliding pill indicator styled like Auth Tab Bar)
  // ---------------------------------------------------------------------------
  Widget _buildSlidingTabBar({
    required int pendingCount,
    required int confirmedCount,
    required int cancelledCount,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary5.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 3;
          return AnimatedBuilder(
            animation: _tabController.animation ?? _tabController,
            builder: (context, _) {
              final animValue =
                  _tabController.animation?.value ??
                  _tabController.index.toDouble();
              final leftOffset = (animValue * tabWidth).clamp(
                0.0,
                constraints.maxWidth - tabWidth,
              );

              return Stack(
                children: [
                  // Physical Sliding active white pill with soft drop shadow
                  Positioned(
                    left: leftOffset,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Tab Labels with Badges
                  Row(
                    children: [
                      _buildSlidingTabItem(
                        label: 'Pending',
                        count: pendingCount,
                        tabIndex: 0,
                        currentProgress: animValue,
                      ),
                      _buildSlidingTabItem(
                        label: 'Confirmed',
                        count: confirmedCount,
                        tabIndex: 1,
                        currentProgress: animValue,
                      ),
                      _buildSlidingTabItem(
                        label: 'Cancelled',
                        count: cancelledCount,
                        tabIndex: 2,
                        currentProgress: animValue,
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSlidingTabItem({
    required String label,
    required int count,
    required int tabIndex,
    required double currentProgress,
  }) {
    final double selectionAmount = (1.0 - (currentProgress - tabIndex).abs())
        .clamp(0.0, 1.0);
    final bool isSelected = selectionAmount > 0.5;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _tabController.animateTo(
            tabIndex,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
          );
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: Color.lerp(
                      AppColors.secondaryDark,
                      AppColors.primaryDark,
                      selectionAmount,
                    ),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.black.withValues(alpha: 0.05),
                      AppColors.primary.withValues(alpha: 0.12),
                      selectionAmount,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color.lerp(
                        AppColors.textSecondary,
                        AppColors.primary,
                        selectionAmount,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTabList({
    required List<CareOrder> orders,
    required String emptyTitle,
    required String emptySubtitle,
    required OrderCategory category,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category == OrderCategory.cancelled
                              ? LucideIcons.circleCheck
                              : LucideIcons.packageSearch,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        emptyTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                          height: 1.4,
                        ),
                      ),
                      if (category != OrderCategory.cancelled) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(RouteNames.products),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.shoppingBag, size: 18),
                          label: const Text(
                            'Explore Hair Products',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(CareOrder order) {
    final statusColor = _getStatusColor(order.status);
    final statusBgColor = _getStatusBgColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final formattedDate = _formatDate(order.orderDate);

    final displayOrderId = order.orderId.length > 16
        ? '#${order.orderId.substring(0, 12)}...'
        : '#${order.orderId}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _openOrderDetails(order),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Order ID + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayOrderId,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 5),
                        Text(
                          order.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.neutral200),
              ),

              // Items summary
              if (order.items.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.package,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.items.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutral900,
                            ),
                          ),
                          if (order.items.length > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+ ${order.items.length - 1} more item${order.items.length > 2 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                          if (order.courierName.isNotEmpty ||
                              order.trackingNumber.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Carrier: ${order.courierName.isNotEmpty ? order.courierName : 'Clinical Logistics'} '
                              '${order.trackingNumber.isNotEmpty ? '(#${order.trackingNumber})' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Estimated Delivery or Delivery Address (if available)
              if (order.estimatedDelivery.isNotEmpty &&
                  order.status.toLowerCase() != 'delivered' &&
                  order.status.toLowerCase() != 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Est. Delivery: ${order.estimatedDelivery}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: Price Total & Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '₹${order.totalAmount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Track Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
