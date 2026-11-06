import 'package:dr_hair/features/shop/presentation/viewmodels/product_details_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/product_details_state.dart';
import 'package:dr_hair/features/shop/presentation/views/product_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  group('ProductSupplyPlan.ensureThreePlans', () {
    test('when admin provides 1 plan, dynamically computes 3 plans with pricing', () {
      final adminPlans = [
        const ProductSupplyPlan(
          title: '1 Month',
          subtitle: 'Starter bottle',
          price: 1000,
          mrp: 1500,
        ),
      ];

      final plans = ProductSupplyPlan.ensureThreePlans(adminPlans);
      expect(plans.length, 3);

      // Plan 1
      expect(plans[0].title, '1 Month');
      expect(plans[0].price, 1000);
      expect(plans[0].mrp, 1500);

      // Plan 2 (2 Months at 10% discount)
      expect(plans[1].title, '2 Months');
      expect(plans[1].price, 1800); // 1000 * 2 * 0.90
      expect(plans[1].mrp, 3000); // 1500 * 2
      expect(plans[1].badge, 'Most Popular');
      expect(plans[1].monthlyPrice, 900);

      // Plan 3 (3 Months at 18% discount)
      expect(plans[2].title, '3 Months');
      expect(plans[2].price, 2460); // 1000 * 3 * 0.82
      expect(plans[2].mrp, 4500); // 1500 * 3
      expect(plans[2].badge, 'Best Value');
      expect(plans[2].monthlyPrice, 820);
    });

    test('when admin provides 3 plans, preserves all admin plans', () {
      final adminPlans = [
        const ProductSupplyPlan(
          title: 'Trial Pack',
          subtitle: '15 Days',
          price: 499,
          mrp: 699,
        ),
        const ProductSupplyPlan(
          title: 'Full Course',
          subtitle: '60 Days',
          price: 1699,
          mrp: 2499,
          badge: 'Popular',
        ),
        const ProductSupplyPlan(
          title: 'Annual Protocol',
          subtitle: '365 Days',
          price: 7999,
          mrp: 12999,
          badge: 'Elite',
        ),
      ];

      final plans = ProductSupplyPlan.ensureThreePlans(adminPlans);
      expect(plans.length, 3);
      expect(plans[0].title, 'Trial Pack');
      expect(plans[1].title, 'Full Course');
      expect(plans[2].title, 'Annual Protocol');
    });

    test('when admin provides 0 plans, generates sensible defaults', () {
      final plans = ProductSupplyPlan.ensureThreePlans(
        [],
        fallbackPrice: 800,
        fallbackMrp: 1200,
      );
      expect(plans.length, 3);
      expect(plans[0].title, '1 Month');
      expect(plans[0].price, 800);
      expect(plans[1].title, '2 Months');
      expect(plans[2].title, '3 Months');
    });
  });
  group('ProductDetailsCubit', () {
    late ProductDetailsCubit cubit;

    setUp(() {
      cubit = ProductDetailsCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default supply plans and values', () {
      expect(cubit.state.quantity, 1);
      expect(cubit.state.selectedSupplyIndex, 1);
      expect(cubit.state.currentUnitPrice, 2339);
      expect(cubit.state.totalPrice, 2339);
      expect(cubit.state.isFavorite, false);
      expect(cubit.state.activeTab, 0);
      expect(cubit.state.product.name, 'Follicle Booster Serum');
    });

    test('selectSupplyPlan updates selected plan and prices', () {
      cubit.selectSupplyPlan(0); // 1 Month plan
      expect(cubit.state.selectedSupplyIndex, 0);
      expect(cubit.state.currentUnitPrice, 1299);
      expect(cubit.state.totalPrice, 1299);

      cubit.selectSupplyPlan(2); // 3 Month plan
      expect(cubit.state.selectedSupplyIndex, 2);
      expect(cubit.state.currentUnitPrice, 3195);
      expect(cubit.state.totalPrice, 3195);
    });

    test('quantity increment and decrement updates total price properly', () {
      cubit.selectSupplyPlan(0); // unit price = 1299
      expect(cubit.state.quantity, 1);
      expect(cubit.state.totalPrice, 1299);

      cubit.incrementQuantity();
      expect(cubit.state.quantity, 2);
      expect(cubit.state.totalPrice, 2598);

      cubit.decrementQuantity();
      expect(cubit.state.quantity, 1);
      expect(cubit.state.totalPrice, 1299);

      // Decrement below 1 should be a no-op
      cubit.decrementQuantity();
      expect(cubit.state.quantity, 1);
    });

    test('removeFromCart resets isAddedToCart and resets quantity to 1', () {
      cubit.addToCart();
      cubit.incrementQuantity();
      expect(cubit.state.isAddedToCart, true);
      expect(cubit.state.quantity, 2);

      cubit.removeFromCart();
      expect(cubit.state.isAddedToCart, false);
      expect(cubit.state.quantity, 1);
    });

    test('toggleFavorite toggles favorite state', () {
      expect(cubit.state.isFavorite, false);
      cubit.toggleFavorite();
      expect(cubit.state.isFavorite, true);
      cubit.toggleFavorite();
      expect(cubit.state.isFavorite, false);
    });

    test('selectTab, selectImage, and setFullscreen update state', () {
      cubit.selectTab(2);
      expect(cubit.state.activeTab, 2);

      cubit.selectImage(1);
      expect(cubit.state.activeImageIndex, 1);

      cubit.setFullscreen(true);
      expect(cubit.state.isFullscreenOpen, true);
      cubit.setFullscreen(false);
      expect(cubit.state.isFullscreenOpen, false);
    });
  });

  group('ProductDetailsView Widget Tests', () {
    testWidgets(
      'renders product details and interacts with supply plans and quantity',
      (tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: ProductDetailsView()));

        // Verify product titles and tags
        expect(find.text('Follicle Booster Serum'), findsOneWidget);
        expect(find.text('Choose Your Regrowth Plan'), findsOneWidget);

        // Verify supply plans
        expect(find.text('1 Month'), findsOneWidget);
        expect(find.text('2 Months'), findsOneWidget);
        expect(find.text('3 Months'), findsOneWidget);

        // Verify initial Add button (defaults to index 1: 2 Months at 2339)
        expect(find.textContaining('Add to cart · ₹2339'), findsOneWidget);

        // Switch to 1 Month plan (price = 1299)
        await tester.ensureVisible(find.text('1 Month'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 Month'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Add to cart · ₹1299'), findsOneWidget);

        // Add to cart to show quantity controls
        await tester.tap(find.textContaining('Add to cart'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('product-added-controls')), findsOneWidget);

        // Increment quantity (+ button)
        await tester.tap(find.byIcon(LucideIcons.plus));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        // Decrement quantity (- button)
        await tester.tap(find.byIcon(LucideIcons.minus));
        await tester.pumpAndSettle();
        expect(find.text('1'), findsWidgets);

        // Remove item from cart by tapping minus button on quantity 1 (trash icon)
        await tester.tap(find.byIcon(LucideIcons.trash2));
        await tester.pumpAndSettle();
        expect(find.textContaining('Add to cart'), findsOneWidget);

        // Verify tabs
        await tester.ensureVisible(find.text('Benefits'));
        expect(find.text('Benefits'), findsOneWidget);
        expect(find.text('Ingredients'), findsOneWidget);
        expect(find.text('How to Use'), findsOneWidget);
        expect(find.text('Sample Results'), findsOneWidget);
      },
    );

    testWidgets('image swiping and thumbnail index synchronization', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = ProductDetailsCubit();
      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsView(cubit: cubit)),
      );

      expect(cubit.state.activeImageIndex, 0);

      // Tap second thumbnail
      final secondThumbnail = find.bySemanticsLabel('Select image 2');
      expect(secondThumbnail, findsOneWidget);
      await tester.tap(secondThumbnail);
      await tester.pumpAndSettle();

      expect(cubit.state.activeImageIndex, 1);

      // Tap third thumbnail
      final thirdThumbnail = find.bySemanticsLabel('Select image 3');
      expect(thirdThumbnail, findsOneWidget);
      await tester.tap(thirdThumbnail);
      await tester.pumpAndSettle();

      expect(cubit.state.activeImageIndex, 2);
    });

    testWidgets('fullscreen viewer open and close interaction', (tester) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = ProductDetailsCubit();
      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsView(cubit: cubit)),
      );

      // Open fullscreen viewer via maximize button
      final fullscreenBtn = find.byIcon(LucideIcons.maximize2);
      expect(fullscreenBtn, findsOneWidget);
      await tester.tap(fullscreenBtn);
      await tester.pumpAndSettle();

      // Verify fullscreen viewer is open
      expect(find.text('1 of 3'), findsOneWidget);
      final closeBtn = find.bySemanticsLabel('Close fullscreen view');
      expect(closeBtn, findsOneWidget);

      // Close fullscreen viewer
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Returned to main view
      expect(find.text('1 of 3'), findsNothing);
      expect(find.text('Follicle Booster Serum'), findsOneWidget);
    });

    testWidgets('favorite toggle updates icon and semantic state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cubit = ProductDetailsCubit();
      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsView(cubit: cubit)),
      );

      expect(cubit.state.isFavorite, false);
      expect(find.bySemanticsLabel('Add to wishlist'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Add to wishlist'));
      await tester.pumpAndSettle();

      expect(cubit.state.isFavorite, true);
      expect(find.bySemanticsLabel('Remove from wishlist'), findsOneWidget);
    });

    testWidgets('suggested products render and show accurate info', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: ProductDetailsView()));

      // Scroll down to suggested products
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('You May Also Like'), findsOneWidget);
      // Suggestions should include other catalog items like Biotin Growth Complex
      expect(find.text('Biotin Growth Complex'), findsOneWidget);
    });

    testWidgets(
      'purchase area remains readable and does not overflow on compact 320x568 screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: ProductDetailsView()));

        // Purchase button should be visible without any overflow
        expect(find.textContaining('Add to cart'), findsOneWidget);

        // Tap Add to cart to show quantity controls and View button
        await tester.tap(find.textContaining('Add to cart'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('product-added-controls')), findsOneWidget);
        expect(find.text('View'), findsOneWidget);
        expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
        expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      },
    );

    testWidgets(
      'ProductDetailsView renders custom initialProduct cleanly without hardcoding',
      (tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final customProduct =
            ProductItem.demoCatalog[1]; // Biotin Growth Complex
        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsView(initialProduct: customProduct)),
        );

        expect(find.text('Biotin Growth Complex'), findsOneWidget);
        expect(
          find.text('DHT Blocker & Keratin Fortification Oral Supplements'),
          findsOneWidget,
        );
        expect(find.textContaining('Add to cart'), findsOneWidget);
        expect(find.text('₹1798'), findsWidgets);
      },
    );

    testWidgets(
      'ProductDetailsView displays unavailable page when product is not found',
      (tester) async {
        final cubit = ProductDetailsCubit(
          initialState: ProductDetailsState.initial(isNotFound: true),
        );
        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsView(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Product unavailable'), findsOneWidget);
        expect(find.text('This product is no longer available.'), findsOneWidget);
        expect(find.text('Browse products'), findsOneWidget);
      },
    );

    testWidgets(
      'Product with only 1 admin-uploaded plan renders 3 plans and switches properly',
      (tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final singlePlanProduct = ProductItem(
          id: 'single-plan-product',
          name: 'Derma Spray',
          subtitle: 'Pure Minoxidil Formula',
          category: 'Treatment',
          rootCause: 'Hair',
          rating: 4.9,
          reviewsCount: 120,
          inStock: true,
          images: const [ProductItem.fallbackProductImageUrl],
          supplyPlans: const [
            ProductSupplyPlan(
              title: '1 Month',
              subtitle: '60ml Solution',
              price: 1000,
              mrp: 1400,
            ),
          ],
          benefits: const [],
          ingredients: const [],
          usageSteps: const [],
          clinicalMetrics: const [],
        );

        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsView(initialProduct: singlePlanProduct)),
        );

        // All 3 plans should be visible on screen
        expect(find.text('1 Month'), findsOneWidget);
        expect(find.text('2 Months'), findsOneWidget);
        expect(find.text('3 Months'), findsOneWidget);

        // Price calculations: 1000 * 2 * 0.90 = 1800 for 2 Months
        expect(find.text('₹1800'), findsWidgets);
        // 1000 * 3 * 0.82 = 2460 for 3 Months
        expect(find.text('₹2460'), findsWidgets);

        // Default selection is 2 Months (index 1) -> 1800
        expect(find.textContaining('Add to cart · ₹1800'), findsOneWidget);

        // Tap 3 Months plan
        await tester.ensureVisible(find.text('3 Months'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('3 Months'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Add to cart · ₹2460'), findsOneWidget);

        // Tap 1 Month plan
        await tester.ensureVisible(find.text('1 Month'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 Month'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Add to cart · ₹1000'), findsOneWidget);
      },
    );

    testWidgets(
      'Skeletonizer applies soft light shimmer theme during loading state',
      (tester) async {
        final cubit = ProductDetailsCubit(
          initialState: ProductDetailsState.initial(isLoading: true),
        );
        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsView(cubit: cubit)),
        );

        final skeletonizer = tester.widget<Skeletonizer>(
          find.byWidgetPredicate((w) => w is Skeletonizer),
        );
        expect(skeletonizer.enabled, true);
        expect(skeletonizer.containersColor, Colors.white);
        expect(skeletonizer.effect, isA<ShimmerEffect>());
        final shimmer = skeletonizer.effect as ShimmerEffect;
        expect(shimmer.colors, contains(const Color(0xFFF1F5F9)));
        expect(shimmer.colors, contains(const Color(0xFFFFFFFF)));
      },
    );

    testWidgets(
      'Interactive tabs header has balanced left and right scroll padding and item gaps',
      (tester) async {
        tester.view.physicalSize = const Size(420, 920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: ProductDetailsView()));
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        final tabScrollViewFinder = find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal &&
              w.padding == const EdgeInsets.symmetric(horizontal: 16),
        );
        expect(tabScrollViewFinder, findsOneWidget);

        final scrollView = tester.widget<SingleChildScrollView>(
          tabScrollViewFinder,
        );
        expect(scrollView.padding, const EdgeInsets.symmetric(horizontal: 16));
        expect(scrollView.physics, isA<BouncingScrollPhysics>());

        // Switch tabs
        await tester.ensureVisible(find.text('Ingredients'));
        await tester.tap(find.text('Ingredients'));
        await tester.pumpAndSettle();
        expect(find.text('Ingredients'), findsOneWidget);
      },
    );
  });
}
