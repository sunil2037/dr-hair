import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../viewmodels/cart_cubit.dart';
import '../viewmodels/product_details_cubit.dart';
import '../viewmodels/product_details_state.dart';

class ProductDetailsView extends StatelessWidget {
  final ProductDetailsCubit? cubit;
  final ProductItem? initialProduct;

  const ProductDetailsView({super.key, this.cubit, this.initialProduct});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProductDetailsCubit>.value(
        value: cubit!,
        child: const _ProductDetailsContent(),
      );
    }
    return BlocProvider<ProductDetailsCubit>(
      create: (_) => ProductDetailsCubit(initialProduct: initialProduct),
      child: const _ProductDetailsContent(),
    );
  }
}

class _ProductDetailsContent extends StatefulWidget {
  const _ProductDetailsContent();

  @override
  State<_ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<_ProductDetailsContent>
    with SingleTickerProviderStateMixin {
  late final PageController _imagePageController;
  late final AnimationController _heartAnimController;
  late final Animation<double> _heartScale;
  bool _isProgrammaticScroll = false;

  final List<String> _tabs = const [
    'Benefits',
    'Ingredients',
    'How to Use',
    'Clinical Results',
  ];

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _heartScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onShare() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(LucideIcons.check, color: AppColors.success, size: 18),
            SizedBox(width: 10),
            Text('Product link copied to clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFullscreenViewer(BuildContext context, ProductDetailsState state) {
    final cubit = context.read<ProductDetailsCubit>();
    cubit.setFullscreen(true);
    _FullscreenGalleryViewer.show(
      context,
      images: state.images,
      initialIndex: state.activeImageIndex,
    ).then((newIndex) {
      if (mounted) {
        cubit.setFullscreen(false);
        if (newIndex != null && newIndex != state.activeImageIndex) {
          _onThumbnailTap(newIndex, cubit);
        }
      }
    });
  }

  void _onThumbnailTap(int index, ProductDetailsCubit cubit) {
    cubit.selectImage(index);
    if (_imagePageController.hasClients &&
        _imagePageController.page?.round() != index) {
      _isProgrammaticScroll = true;
      _imagePageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          )
          .then((_) => _isProgrammaticScroll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
      listenWhen: (previous, current) =>
          previous.isFavorite != current.isFavorite ||
          previous.activeImageIndex != current.activeImageIndex,
      listener: (context, state) {
        if (!_isProgrammaticScroll &&
            _imagePageController.hasClients &&
            _imagePageController.page?.round() != state.activeImageIndex) {
          _imagePageController.animateToPage(
            state.activeImageIndex,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProductDetailsCubit>();
        final product = state.product;
        final suggestions = ProductItem.getSuggestedProducts(product.id);
        final heroHeight = (MediaQuery.sizeOf(context).height * 0.36)
            .clamp(240.0, 320.0)
            .toDouble();

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Clean Pinned App Bar
              SliverAppBar(
                pinned: true,
                surfaceTintColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                backgroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Semantics(
                    label: 'Go back',
                    button: true,
                    child: _buildHeaderIconButton(
                      icon: LucideIcons.arrowLeft,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                actions: [
                  Semantics(
                    label: state.isFavorite
                        ? 'Remove from wishlist'
                        : 'Add to wishlist',
                    button: true,
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: _buildHeaderIconButton(
                        icon: state.isFavorite
                            ? Icons.favorite
                            : LucideIcons.heart,
                        iconColor: state.isFavorite
                            ? AppColors.danger
                            : AppColors.primaryDark,
                        tooltip: 'Wishlist',
                        onTap: () {
                          cubit.toggleFavorite();
                          if (!MediaQuery.disableAnimationsOf(context)) {
                            _heartAnimController.forward(from: 0.0);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    label: 'Share product',
                    button: true,
                    child: _buildHeaderIconButton(
                      icon: LucideIcons.share2,
                      tooltip: 'Share',
                      onTap: _onShare,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    label: 'Notifications',
                    button: true,
                    child: _buildHeaderIconButton(
                      icon: LucideIcons.bell,
                      tooltip: 'Notifications',
                      onTap: () => context.push(RouteNames.notifications),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),

              // Hero Image Gallery with Zoom trigger and Thumbnails
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Image PageView with Tap to Zoom
                      SizedBox(
                        height: heroHeight,
                        child: Stack(
                          children: [
                            Semantics(
                              label: 'Product image, tap to view fullscreen',
                              button: true,
                              child: GestureDetector(
                                onTap: () =>
                                    _openFullscreenViewer(context, state),
                                child: PageView.builder(
                                  controller: _imagePageController,
                                  itemCount: state.images.length,
                                  onPageChanged: (index) {
                                    if (!_isProgrammaticScroll) {
                                      cubit.selectImage(index);
                                    }
                                  },
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      child: Hero(
                                        tag:
                                            'product_image_${product.id}_$index',
                                        child: CustomCachedImage(
                                          imageUrl: state.images[index],
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                          borderRadius: 0,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Fullscreen zoom indicator button
                            Positioned(
                              bottom: 12,
                              right: 16,
                              child: Semantics(
                                label: 'Open fullscreen image viewer',
                                button: true,
                                child: Material(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  shadowColor: Colors.black26,
                                  child: IconButton(
                                    icon: const Icon(
                                      LucideIcons.maximize2,
                                      size: 18,
                                      color: AppColors.primaryDark,
                                    ),
                                    tooltip: 'View fullscreen',
                                    onPressed: () =>
                                        _openFullscreenViewer(context, state),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Restrained Tappable Thumbnail Strip
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(state.images.length, (index) {
                            final isSelected = state.activeImageIndex == index;
                            return Semantics(
                              label: 'Select image ${index + 1}',
                              button: true,
                              selected: isSelected,
                              child: GestureDetector(
                                onTap: () => _onThumbnailTap(index, cubit),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CustomCachedImage(
                                      imageUrl: state.images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Info & Selection Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Product Title
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        product.subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.secondaryDark,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rating & Stock Row (Wrap prevents any overflow on small devices)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary5,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  color: AppColors.starGold,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${product.reviewsCount} reviews)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
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
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  color: AppColors.success,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'In Stock • Ships Free',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Price and Discount
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '₹${state.currentUnitPrice}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'MRP ₹${state.currentUnitMrp}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save ${state.discountPercentage}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Inclusive of all taxes • Authentic Formulation Guaranteed',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Supply Plan Selection
                      const Text(
                        'Choose Your Regrowth Plan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Plans Horizontal Row
                      Row(
                        children: List.generate(state.supplyPlans.length, (
                          index,
                        ) {
                          final plan = state.supplyPlans[index];
                          final isSelected = state.selectedSupplyIndex == index;

                          return Expanded(
                            child: Semantics(
                              label:
                                  '${plan.title} plan, ₹${plan.price}. ${plan.badge ?? ''}',
                              button: true,
                              selected: isSelected,
                              child: GestureDetector(
                                onTap: () => cubit.selectSupplyPlan(index),
                                child: AnimatedContainer(
                                  constraints: const BoxConstraints(
                                    minHeight: 90,
                                  ),
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.only(
                                    right: index < state.supplyPlans.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary5
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (plan.badge != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.primary5,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            plan.badge!,
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 6),
                                      Text(
                                        plan.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? AppColors.primaryDark
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${plan.price}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Clinical Trust Badges (clean 3-column guarantee)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: _TrustBadge(
                                icon: LucideIcons.shieldCheck,
                                label: 'Doctor\nApproved',
                              ),
                            ),
                            Expanded(
                              child: _TrustBadge(
                                icon: LucideIcons.leaf,
                                label: '100% Vegan\n& Cruelty-Free',
                              ),
                            ),
                            Expanded(
                              child: _TrustBadge(
                                icon: LucideIcons.award,
                                label: '90-Day Results\nGuarantee',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Interactive Tabs Header
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isTabSelected = state.activeTab == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Semantics(
                                label: '${_tabs[index]} tab',
                                selected: isTabSelected,
                                button: true,
                                child: GestureDetector(
                                  onTap: () => cubit.selectTab(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTabSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isTabSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      _tabs[index],
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isTabSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isTabSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tab Content Body
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildTabContent(state.activeTab, product),
                      ),

                      const SizedBox(height: 32),

                      // Suggested Products: "You May Also Like"
                      if (suggestions.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You May Also Like',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Frequently paired clinical essentials (Demo)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push(RouteNames.cart),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 215,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: suggestions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = suggestions[index];
                              return _SuggestedProductCard(
                                product: item,
                                onTap: () {
                                  context.push(
                                    RouteNames.productDetails,
                                    extra: item,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Purchase action stays compact until the selected product is in the cart.
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final cart = context.read<CartCubit?>();
                  Widget buildBottomBar(
                    BuildContext barContext, [
                    CartState? cartState,
                  ]) {
                    final cartQuantity =
                        cart?.quantityFor(
                          product.id,
                          state.selectedSupplyPlan.title,
                        ) ??
                        0;
                    final quantity = cartQuantity > 0
                        ? cartQuantity
                        : state.quantity;
                    final isInCart =
                        cartQuantity > 0 || (cart == null && state.isAddedToCart);
                    final total = state.currentUnitPrice * quantity;
                    final reduceMotion = MediaQuery.disableAnimationsOf(barContext);
                    return AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 260),
                      reverseDuration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: isInCart
                          ? Row(
                              key: const ValueKey('product-added-controls'),
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹$total',
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '$quantity × ${state.selectedSupplyPlan.title} plan',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.secondaryDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: quantity <= 1
                                            ? 'Remove from cart'
                                            : 'Decrease quantity',
                                        onPressed: () {
                                          if (quantity <= 1) {
                                            final lineId = CartCubit.lineId(
                                              product.id,
                                              state.selectedSupplyPlan.title,
                                            );
                                            cart?.remove(lineId);
                                            cubit.removeFromCart();
                                            HapticFeedback.lightImpact();
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                SnackBar(
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  backgroundColor:
                                                      AppColors.primaryDark,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  content: Text(
                                                    'Removed ${product.name} from cart',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              );
                                          } else {
                                            final next = quantity - 1;
                                            cubit.setQuantity(next);
                                            cart?.setQuantity(
                                              CartCubit.lineId(
                                                product.id,
                                                state
                                                    .selectedSupplyPlan
                                                    .title,
                                              ),
                                              next,
                                            );
                                            HapticFeedback.selectionClick();
                                          }
                                        },
                                        icon: Icon(
                                          quantity <= 1
                                              ? LucideIcons.trash2
                                              : LucideIcons.minus,
                                          size: 16,
                                          color: quantity <= 1
                                              ? AppColors.danger
                                              : AppColors.primaryDark,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 42,
                                          minHeight: 42,
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: reduceMotion
                                            ? Duration.zero
                                            : const Duration(milliseconds: 160),
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                        child: Text(
                                          '$quantity',
                                          key: ValueKey(quantity),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Increase quantity',
                                        onPressed: quantity >= 10
                                            ? null
                                            : () {
                                                final next = quantity + 1;
                                                cubit.setQuantity(next);
                                                cart?.setQuantity(
                                                  CartCubit.lineId(
                                                    product.id,
                                                    state
                                                        .selectedSupplyPlan
                                                        .title,
                                                  ),
                                                  next,
                                                );
                                                HapticFeedback.selectionClick();
                                              },
                                        icon: const Icon(
                                          LucideIcons.plus,
                                          size: 16,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 42,
                                          minHeight: 42,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    context.push(RouteNames.cart);
                                  },
                                  icon: const Icon(
                                    LucideIcons.shoppingCart,
                                    size: 17,
                                  ),
                                  label: const Text('View'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(92, 46),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              key: const ValueKey('add-product-button'),
                              width: double.infinity,
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: product.inStock
                                    ? () {
                                        cart?.addProduct(
                                          product: product,
                                          plan: state.selectedSupplyPlan,
                                          quantity: state.quantity,
                                        );
                                        cubit.addToCart();
                                        HapticFeedback.lightImpact();
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              content: const Text(
                                                'Added to your cart',
                                              ),
                                            ),
                                          );
                                      }
                                    : null,
                                icon: const Icon(
                                  LucideIcons.shoppingCart,
                                  size: 18,
                                ),
                                label: Text(
                                  product.inStock
                                      ? 'Add to cart · ₹${state.totalPrice}'
                                      : 'Currently unavailable',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.border,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                    );
                  }

                  if (cart != null) {
                    return BlocBuilder<CartCubit, CartState>(
                      bloc: cart,
                      builder: buildBottomBar,
                    );
                  }
                  return buildBottomBar(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    Color? iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, size: 18, color: iconColor ?? AppColors.primaryDark),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, ProductItem product) {
    switch (tabIndex) {
      case 0: // Benefits
        return Column(
          key: const ValueKey('benefits_tab'),
          children: product.benefits.map((benefit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          benefit.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryDark,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 1: // Ingredients
        return Column(
          key: const ValueKey('ingredients_tab'),
          children: product.ingredients.map((ing) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ing.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ing.purpose,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ing.concentration,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 2: // How to Use
        return Column(
          key: const ValueKey('how_to_use_tab'),
          children: product.usageSteps.map((step) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${step.step}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryDark,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 3: // Clinical Results
      default:
        return Column(
          key: const ValueKey('clinical_tab'),
          children: product.clinicalMetrics.map((metric) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    metric.percentage,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.claim,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metric.source,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
    }
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryDark,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SuggestedProductCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;

  const _SuggestedProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Suggested product: ${product.name}, price ₹${product.supplyPlans.first.price}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 95,
                  width: double.infinity,
                  child: CustomCachedImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${product.supplyPlans.first.price}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.star,
                        size: 11,
                        color: AppColors.starGold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
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

class _FullscreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  static Future<int?> show(
    BuildContext context, {
    required List<String> images,
    required int initialIndex,
  }) {
    return Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black,
        pageBuilder: (context, anim, secondaryAnim) {
          return FadeTransition(
            opacity: anim,
            child: _FullscreenGalleryViewer(
              images: images,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  State<_FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: CustomCachedImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                    ),
                  );
                },
              ),

              // Header bar with close button & counter
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Close fullscreen view',
                      button: true,
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Close',
                        onPressed: () =>
                            Navigator.of(context).pop(_currentIndex),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
