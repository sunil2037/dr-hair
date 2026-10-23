import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../home/presentation/widgets/medicine_card.dart';
import '../../data/models/product_model.dart';

/// Dedicated Products Screen showing all dermatologist and ayurvedic hair care products
/// using the exact [MedicineCard] from the home screen. Tapping opens [ProductDetailsView]
/// with genuine product data.
class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String _selectedCategory = 'All';

  static final ProductItem _customKitProduct = ProductItem(
    id: 'traya-custom-regrowth-kit',
    name: '3-Month Hair Regrowth Kit',
    subtitle: 'Follicle Booster Serum + Ayurvedic Scalp Oil + DHT Blocker Supplements',
    category: 'Doctor & Ayurvedic Regimen',
    rating: 4.95,
    reviewsCount: 3820,
    inStock: true,
    images: const [
      'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
      'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
      'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
    ],
    supplyPlans: const [
      ProductSupplyPlan(
        title: 'Complete Kit',
        subtitle: 'Serum + Oil + DHT Herbal Capsules',
        price: 1445,
        mrp: 2044,
        badge: 'SAVINGS 29%',
      ),
      ProductSupplyPlan(
        title: '6 Months Protocol',
        subtitle: 'Double Kit + Scalp Dermaroller',
        price: 2699,
        mrp: 4088,
        badge: 'BEST VALUE',
      ),
    ],
    benefits: const [
      ProductBenefitItem(
        title: 'Dual-Science Regimen',
        description: 'Combines dermatological actives with classical Ayurvedic scalp therapy.',
      ),
      ProductBenefitItem(
        title: 'Addresses 3 Root Causes',
        description: 'Actively tackles scalp dandruff, DHT miniaturization, and micro-nutrient deficiencies.',
      ),
      ProductBenefitItem(
        title: '93% Observed Visual Results',
        description: 'Significant reduction in shedding within 45 days and hairline thickening by Month 5.',
      ),
    ],
    ingredients: const [
      ProductIngredientItem(
        name: 'Redensyl + Procapil',
        concentration: '8.0% Complex',
        purpose: 'Stem cell follicular reactivation & localized DHT blockage.',
      ),
      ProductIngredientItem(
        name: 'Kshirpak Bhringraj',
        concentration: '100% Ayurvedic',
        purpose: 'Cools scalp, clears follicular inflammation & promotes deep root anchoring.',
      ),
      ProductIngredientItem(
        name: 'Saw Palmetto & Zinc',
        concentration: '500mg',
        purpose: 'Natural 5-alpha-reductase inhibitor to protect follicles internally.',
      ),
    ],
    usageSteps: const [
      ProductUsageStep(
        step: 1,
        title: 'Apply Follicle Serum',
        description: 'Apply 1ml of serum to clean, dry scalp every morning and massage lightly.',
      ),
      ProductUsageStep(
        step: 2,
        title: 'Scalp Oil Therapy',
        description: 'Apply herbal oil 3 nights a week before bedtime to nourish roots.',
      ),
      ProductUsageStep(
        step: 3,
        title: 'Daily Nutrition Capsule',
        description: 'Take 1 capsule post-dinner with water for internal hormonal balance.',
      ),
    ],
    clinicalMetrics: const [
      ProductClinicalMetric(
        percentage: '93%',
        claim: 'saw significant hair shedding reduction',
        source: 'Dr. Hair Clinical Registry Dec 2022',
      ),
      ProductClinicalMetric(
        percentage: '89%',
        claim: 'experienced crown density improvement',
        source: 'Dermatological Trial Protocol',
      ),
    ],
  );

  List<ProductItem> get _allProducts => [
        _customKitProduct,
        ...ProductItem.demoCatalog,
      ];

  List<ProductItem> get _filteredProducts {
    if (_selectedCategory == 'All') return _allProducts;
    if (_selectedCategory == 'Dermatologist') {
      return _allProducts.where((p) => p.category.toLowerCase().contains('dermatologist')).toList();
    }
    if (_selectedCategory == 'Ayurveda') {
      return _allProducts.where((p) => p.category.toLowerCase().contains('ayurved')).toList();
    }
    if (_selectedCategory == 'Kits') {
      return _allProducts.where((p) => p.id.contains('kit')).toList();
    }
    return _allProducts;
  }

  MedicineCategory _getCategory(ProductItem product) {
    if (product.category.toLowerCase().contains('ayurved')) {
      return MedicineCategory.ayurveda;
    }
    return MedicineCategory.dermatologist;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Kits', 'Dermatologist', 'Ayurveda'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Products & Treatments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shoppingBag, color: AppColors.primaryDark),
            tooltip: 'My Cart',
            onPressed: () => context.push(RouteNames.cart),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.primary5,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.primaryDark,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.primary100,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Products Grid / List
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
                    child: Text('No products found in this category.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final firstPrice = product.supplyPlans.isNotEmpty
                          ? '₹${product.supplyPlans.first.price}'
                          : '₹999';

                      return MedicineCard(
                        width: double.infinity,
                        title: product.name,
                        desc: product.subtitle,
                        price: firstPrice,
                        imageUrl: product.images.first,
                        category: _getCategory(product),
                        rating: product.rating,
                        showAddToCart: false,
                        onTap: () {
                          context.push(RouteNames.productDetails, extra: product);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
