import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../viewmodels/cart_cubit.dart';

class CartView extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;

  const CartView({super.key, this.initialItems});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late List<Map<String, dynamic>> _localItems;
  List<Map<String, dynamic>> get _items =>
      context.read<CartCubit?>()?.state.items ?? _localItems;

  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;

  @override
  void initState() {
    super.initState();
    _localItems = widget.initialItems != null
        ? List<Map<String, dynamic>>.from(
            widget.initialItems!.map((item) => Map<String, dynamic>.from(item)),
          )
        : [
            {
              'title': 'Follicle Booster Serum',
              'desc': 'Advance Density Complex • 30ml',
              'price': 1299,
              'quantity': 1,
              'image': 'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=400',
            },
            {
              'title': 'Clinical Scalp Detox Shampoo',
              'desc': 'Anti-Microbial Zinc Pyrithione • 200ml',
              'price': 749,
              'quantity': 1,
              'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400',
            },
          ];
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int get _subtotal => _items.fold(
    0,
    (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int),
  );

  int get _totalItemCount =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  int get _discount => _couponApplied ? 200 : 0;

  int get _totalAmount {
    final total = _subtotal - _discount;
    return total < 0 ? 0 : total;
  }

  void _incrementQuantity(int index) {
    if (_items[index]['quantity'] < 10) {
      final sharedCart = context.read<CartCubit?>();
      if (sharedCart != null) {
        sharedCart.setQuantity(
          _items[index]['id'] as String,
          (_items[index]['quantity'] as int) + 1,
        );
      } else {
        setState(() {
          _localItems[index]['quantity'] =
              (_localItems[index]['quantity'] as int) + 1;
        });
      }
      HapticFeedback.selectionClick();
    }
  }

  void _decrementQuantity(int index) {
    if ((_items[index]['quantity'] as int) > 1) {
      final sharedCart = context.read<CartCubit?>();
      if (sharedCart != null) {
        sharedCart.setQuantity(
          _items[index]['id'] as String,
          (_items[index]['quantity'] as int) - 1,
        );
      } else {
        setState(() {
          _localItems[index]['quantity'] =
              (_localItems[index]['quantity'] as int) - 1;
        });
      }
      HapticFeedback.selectionClick();
    } else {
      _removeItem(index);
    }
  }

  void _removeItem(int index) {
    final removed = Map<String, dynamic>.from(_items[index]);
    final sharedCart = context.read<CartCubit?>();
    if (sharedCart != null) {
      sharedCart.remove(removed['id'] as String);
    } else {
      setState(() => _localItems.removeAt(index));
    }
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: Text(
          'Removed ${removed['title']} from cart',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _clearCart() {
    if (_items.isEmpty) return;
    final sharedCart = context.read<CartCubit?>();
    if (sharedCart != null) {
      sharedCart.clear();
      setState(() => _couponApplied = false);
    } else {
      setState(() {
        _localItems.clear();
        _couponApplied = false;
      });
    }
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: const Text('Cart cleared'),
      ),
    );
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'FIRSTDR') {
      setState(() {
        _couponApplied = true;
      });
      HapticFeedback.lightImpact();
    } else {
      setState(() {
        _couponApplied = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied = false;
      _couponController.clear();
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.read<CartCubit?>();
    if (cartCubit != null) {
      return BlocBuilder<CartCubit, CartState>(
        builder: (context, state) => _buildScaffold(context),
      );
    }
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _clearCart,
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _items.isEmpty
          ? _buildEmptyState(context)
          : _buildCartContent(context),
      bottomNavigationBar: _items.isEmpty ? null : _buildCheckoutBar(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Illustration
            Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/SearchWithCross.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.shoppingBag,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Looks like you haven\'t added any hair treatments yet. Explore our doctor-approved formulations to begin your hair health journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.secondaryDark,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Explore Treatments Button
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(RouteNames.mainShell);
                }
              },
              icon: const Icon(LucideIcons.sparkles, size: 16),
              label: const Text(
                'Explore Treatments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Keep the demo reset affordance only in standalone preview mode.
            if (context.read<CartCubit?>() == null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _localItems = [
                      {
                        'title': 'Follicle Booster Serum',
                        'desc': 'Advance Density Complex • 30ml',
                        'price': 1299,
                        'quantity': 1,
                        'image': 'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=400',
                      },
                      {
                        'title': 'Clinical Scalp Detox Shampoo',
                        'desc': 'Anti-Microbial Zinc Pyrithione • 200ml',
                        'price': 749,
                        'quantity': 1,
                        'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400',
                      },
                    ];
                  });
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(
                  LucideIcons.rotateCcw,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Reset Demo Cart Items',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sanctuary Clinical Assurance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clinical Regimen Curated • Authentic formulations guaranteed with free dermatologist review',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.secondaryDark,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Items Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart Items ($_totalItemCount)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Row(
                children: [
                  Icon(LucideIcons.truck, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Free Express Shipping',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Cart Items List
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Dismissible(
              key: ValueKey('cart_item_${item['title']}_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trash2, color: AppColors.danger, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) => _removeItem(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCachedImage(
                      imageUrl: item['image'] as String,
                      width: 72,
                      height: 72,
                      borderRadius: 14,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove ${item['title']}',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => _removeItem(index),
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item['desc'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${item['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),

                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Decrease quantity',
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      onPressed: () =>
                                          _decrementQuantity(index),
                                      icon: const Icon(
                                        LucideIcons.minus,
                                        size: 14,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '${item['quantity']}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Increase quantity',
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      onPressed: () =>
                                          _incrementQuantity(index),
                                      icon: const Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Coupon Code Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apply Sanctuary Reward',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(LucideIcons.tag, size: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_couponApplied)
                      OutlinedButton(
                        onPressed: _removeCoupon,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Remove'),
                      )
                    else
                      FilledButton(
                        onPressed: _applyCoupon,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                  ],
                ),
                if (_couponApplied) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 14,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'FIRSTDR applied. ₹200 saved.',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (_couponController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Enter FIRSTDR to apply the available reward.',
                    style: TextStyle(
                      color: AppColors.secondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Subtotal', '₹$_subtotal'),
                if (_couponApplied)
                  _buildSummaryRow(
                    'Sanctuary Reward (FIRSTDR)',
                    '- ₹$_discount',
                    isDiscount: true,
                  ),
                _buildSummaryRow('Clinical Delivery Fee', 'FREE', isFree: true),
                _buildSummaryRow('Tax & Consult Charge', 'Included'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _buildSummaryRow(
                  'Total Amount',
                  '₹$_totalAmount',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹$_totalAmount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '$_totalItemCount items • Free Delivery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(RouteNames.checkout, extra: _totalAmount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isFree = false,
  }) {
    Color valueColor;
    if (isDiscount || isFree) {
      valueColor = AppColors.success;
    } else if (isTotal) {
      valueColor = AppColors.primary;
    } else {
      valueColor = AppColors.primaryDark;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? AppColors.primaryDark : AppColors.secondaryDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
