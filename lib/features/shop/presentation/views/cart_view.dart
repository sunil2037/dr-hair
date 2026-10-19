import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_cached_image.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Follicle Booster Serum',
      'desc': 'Advance Density Complex • 30ml',
      'price': 1299,
      'quantity': 1,
      'image':
          'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=400',
    },
    {
      'title': 'Clinical Scalp Detox Shampoo',
      'desc': 'Anti-Microbial Zinc Pyrithione • 200ml',
      'price': 749,
      'quantity': 1,
      'image':
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=400',
    },
  ];

  int get _subtotal => _items.fold(
      0, (sum, item) => sum + (item['price'] as int) * (item['quantity'] as int));

  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;

  int get _discount => _couponApplied ? 200 : 0;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                children: [
                  // Quote Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(18),
                      border: const Border(
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                    ),
                    child: const Text(
                      'Your sanctuary selection is waiting. These clinical-grade formulas are curated for your hair health journey.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryDark,
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cart Items
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CustomCachedImage(
                            imageUrl: item['image'] as String,
                            width: 70,
                            height: 70,
                            borderRadius: 16,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      onPressed: () {
                                        setState(() {
                                          _items.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${item['price']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary5,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Decrease quantity',
                                            onPressed: () {
                                              if (item['quantity'] > 1) {
                                                setState(
                                                    () => item['quantity']--);
                                              }
                                            },
                                            icon: const Icon(
                                                LucideIcons.minus,
                                                size: 16),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text(
                                              '${item['quantity']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Increase quantity',
                                            onPressed: () => setState(
                                                () => item['quantity']++),
                                            icon: const Icon(LucideIcons.plus,
                                                size: 16),
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
                    );
                  }),

                  const SizedBox(height: 20),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.primary100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryRow('Subtotal', '₹$_subtotal'),
                        _buildSummaryRow('Discount (FIRSTDR)', '- ₹$_discount'),
                        _buildSummaryRow('Delivery Fee', 'FREE'),
                        _buildSummaryRow('Clinical Tax (GST)', 'Included'),
                        const Divider(color: AppColors.border, height: 20),
                        _buildSummaryRow('Total Amount', '₹${_subtotal - _discount}',
                            isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Apply Sanctuary Reward', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter coupon code',
                              prefixIcon: Icon(LucideIcons.tag),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          )),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: () => setState(() {
                              _couponApplied = _couponController.text.trim().toUpperCase() == 'FIRSTDR';
                            }),
                            child: const Text('Apply'),
                          ),
                        ]),
                        if (_couponApplied) ...[
                          const SizedBox(height: 8),
                          const Text('FIRSTDR applied. ₹200 saved.', style: TextStyle(color: AppColors.success, fontSize: 12)),
                        ] else if (_couponController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Enter FIRSTDR to apply the available reward.', style: TextStyle(color: AppColors.secondaryDark, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        RouteNames.checkout,
                        extra: _subtotal - _discount,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? AppColors.primaryDark : AppColors.secondaryDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? AppColors.primary : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
