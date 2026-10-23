import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../data/models/product_model.dart';
import '../viewmodels/cart_cubit.dart';

/// Category Tab Model for clinical root cause navigation
class _CategoryTabItem {
  final String id;
  final String label;
  final IconData icon;

  const _CategoryTabItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Dedicated Medicines & Products screen using [NestedScrollView] with SliverAppBar,
/// category TabBar for clinical root causes (Thyroid, Dandruff, Hair, Stress, Gut, PCOS, Hormone),
/// 2-column responsive product grid cards, and search icon beside cart button.
class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  static const List<_CategoryTabItem> _categories = [
    _CategoryTabItem(id: 'all', label: 'All', icon: LucideIcons.layoutGrid),
    _CategoryTabItem(id: 'hair', label: 'Hair', icon: LucideIcons.sparkles),
    _CategoryTabItem(
      id: 'dandruff',
      label: 'Dandruff',
      icon: LucideIcons.shieldCheck,
    ),
    _CategoryTabItem(id: 'gut', label: 'Gut', icon: LucideIcons.apple),
    _CategoryTabItem(id: 'stress', label: 'Stress', icon: LucideIcons.brain),
    _CategoryTabItem(
      id: 'thyroid',
      label: 'Thyroid',
      icon: LucideIcons.activity,
    ),
    _CategoryTabItem(id: 'pcos', label: 'PCOS', icon: LucideIcons.flower2),
    _CategoryTabItem(id: 'hormone', label: 'Hormone', icon: LucideIcons.dna),
  ];

  static final ProductItem _customKitProduct = ProductItem(
    id: 'traya-custom-regrowth-kit',
    name: '3-Month Hair Regrowth Kit',
    subtitle: 'Follicle Booster Serum + Scalp Oil + DHT Blocker Supplements',
    category: 'Doctor & Ayurvedic Regimen',
    rootCause: 'Hair',
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
        title: 'Addresses Root Causes',
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
        description:
            'Apply herbal oil 3 nights a week before bedtime to nourish roots.',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ProductItem> _getFilteredProductsForCategory(String categoryId) {
    Iterable<ProductItem> products = _allProducts;

    switch (categoryId) {
      case 'hair':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final cat = p.category.toLowerCase();
          final name = p.name.toLowerCase();
          return root == 'hair' ||
              cat.contains('hair') ||
              name.contains('hair') ||
              name.contains('follicle') ||
              p.id.contains('regrowth') ||
              p.id.contains('serum');
        });
        break;
      case 'dandruff':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final cat = p.category.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'dandruff' ||
              cat.contains('dandruff') ||
              name.contains('dandruff') ||
              sub.contains('dandruff') ||
              name.contains('shampoo') ||
              sub.contains('ketoconazole') ||
              p.id.contains('dandruff');
        });
        break;
      case 'gut':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'gut' ||
              name.contains('gut') ||
              sub.contains('gut') ||
              name.contains('triphala') ||
              sub.contains('probiotics') ||
              p.id.contains('gut');
        });
        break;
      case 'stress':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'stress' ||
              name.contains('stress') ||
              sub.contains('stress') ||
              name.contains('ashwagandha') ||
              name.contains('shiro') ||
              p.id.contains('calm');
        });
        break;
      case 'thyroid':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'thyroid' ||
              name.contains('thyro') ||
              sub.contains('thyroid') ||
              sub.contains('metabol') ||
              p.id.contains('thyro');
        });
        break;
      case 'pcos':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'pcos' ||
              name.contains('pcos') ||
              sub.contains('pcos') ||
              sub.contains('inositol') ||
              p.id.contains('pcos');
        });
        break;
      case 'hormone':
        products = products.where((p) {
          final root = p.rootCause.toLowerCase();
          final name = p.name.toLowerCase();
          final sub = p.subtitle.toLowerCase();
          return root == 'hormone' ||
              name.contains('hormon') ||
              name.contains('dht') ||
              sub.contains('dht') ||
              sub.contains('hormon') ||
              p.id.contains('dht');
        });
        break;
      case 'all':
      default:
        break;
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      products = products.where((product) {
        final inName = product.name.toLowerCase().contains(query);
        final inSubtitle = product.subtitle.toLowerCase().contains(query);
        final inCategory = product.category.toLowerCase().contains(query);
        final inRoot = product.rootCause.toLowerCase().contains(query);
        final inIngredients = product.ingredients.any(
          (i) =>
              i.name.toLowerCase().contains(query) ||
              i.purpose.toLowerCase().contains(query),
        );
        final inBenefits = product.benefits.any(
          (b) =>
              b.title.toLowerCase().contains(query) ||
              b.description.toLowerCase().contains(query),
        );
        return inName ||
            inSubtitle ||
            inCategory ||
            inRoot ||
            inIngredients ||
            inBenefits;
      });
    }

    return products.toList(growable: false);
  }

  void _handleAddToCart(ProductItem product) {
    final plan = product.supplyPlans.isNotEmpty
        ? product.supplyPlans.first
        : ProductSupplyPlan(
            title: 'Standard',
            subtitle: product.subtitle,
            price: 999,
            mrp: 1299,
          );

    final cartCubit = context.read<CartCubit?>();
    if (cartCubit != null) {
      cartCubit.addProduct(product: product, plan: plan, quantity: 1);
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(
              LucideIcons.checkCircle2,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${product.name} added to cart',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: AppColors.primary100,
          onPressed: () => context.push(RouteNames.cart),
        ),
      ),
    );
  }

  void _onSearchIconPressed() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: true,
                snap: false,
                elevation: innerBoxIsScrolled ? 1 : 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Medicines & Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                actions: [
                  // 1. Cart Button with badge
                  _buildCartButton(context),

                  // 2. Search Icon on right side of cart button
                  IconButton(
                    key: const ValueKey('appbar-search-button'),
                    icon: const Icon(
                      LucideIcons.search,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    tooltip: 'Search products',
                    onPressed: _onSearchIconPressed,
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(104),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildSearchBar(), _buildTabBar()],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Builder(
                builder: (BuildContext context) {
                  final products = _getFilteredProductsForCategory(category.id);
                  return CustomScrollView(
                    key: PageStorageKey<String>(category.id),
                    slivers: <Widget>[
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      if (products.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.sizeOf(context).width >= 1000
                                      ? 4
                                      : MediaQuery.sizeOf(context).width >= 640
                                      ? 3
                                      : 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  mainAxisExtent: 244,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final product = products[index];
                              return _ProductGridCard(
                                product: product,
                                onTap: () => context.push(
                                  RouteNames.productDetails,
                                  extra: product,
                                ),
                                onAddToCart: () => _handleAddToCart(product),
                              );
                            }, childCount: products.length),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    final cartCubit = context.read<CartCubit?>();
    if (cartCubit == null) {
      return IconButton(
        icon: const Icon(LucideIcons.shoppingBag, color: AppColors.primaryDark),
        tooltip: 'My Cart',
        onPressed: () => context.push(RouteNames.cart),
      );
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final count = cartState.itemCount;
        return Semantics(
          label: 'Shopping Cart with $count items',
          button: true,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  LucideIcons.shoppingBag,
                  color: AppColors.primaryDark,
                ),
                tooltip: 'My Cart',
                onPressed: () => context.push(RouteNames.cart),
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
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
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        key: const ValueKey('product-search'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search medicines, products, ingredients…',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: _categories.map((cat) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 14),
                const SizedBox(width: 6),
                Text(cat.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary5,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No matching products',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another condition, ingredient, or clear search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _tabController.animateTo(0);
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clinical Product Card designed specifically for the 2-column grid
class _ProductGridCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductGridCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final plan = product.supplyPlans.isNotEmpty
        ? product.supplyPlans.first
        : null;
    final price = plan != null ? '₹${plan.price}' : 'Price N/A';
    final mrp = plan != null && plan.mrp > plan.price ? '₹${plan.mrp}' : null;
    final discountPercent = plan != null && plan.mrp > plan.price
        ? (((plan.mrp - plan.price) / plan.mrp) * 100).round()
        : null;

    final isAyurveda = product.category.toLowerCase().contains('ayurved');
    final tagLabel = product.rootCause.isNotEmpty
        ? product.rootCause
        : (isAyurveda ? 'Ayurveda' : 'Clinical');

    return Semantics(
      label: '${product.name}, $price, ${product.rating} stars',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with category badge, discount & rating
                  Stack(
                    children: [
                      CustomCachedImage(
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : '',
                        height: 104,
                        width: double.infinity,
                        borderRadius: 14,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: 104,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isAyurveda ? LucideIcons.leaf : LucideIcons.pill,
                            color: isAyurveda
                                ? AppColors.success
                                : AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),

                      // Root cause badge (Top-Left)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAyurveda
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tagLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isAyurveda
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      // Discount badge (Top-Right)
                      if (discountPercent != null && discountPercent > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$discountPercent% OFF',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Rating badge (Bottom-Right)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: AppColors.starGold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Product Title
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Subtitle / Active key ingredients
                  Text(
                    product.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Price and Add button Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (mrp != null)
                              Text(
                                mrp,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onAddToCart,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary5,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.plus,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
