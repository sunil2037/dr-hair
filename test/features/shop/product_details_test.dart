import 'package:dr_hair/features/shop/presentation/viewmodels/product_details_cubit.dart';
import 'package:dr_hair/features/shop/presentation/viewmodels/product_details_state.dart';
import 'package:dr_hair/features/shop/presentation/views/product_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
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
      expect(cubit.state.currentUnitPrice, 2799);
      expect(cubit.state.totalPrice, 2799);
      expect(cubit.state.isFavorite, false);
      expect(cubit.state.activeTab, 0);
      expect(cubit.state.product.name, 'Follicle Booster Serum');
    });

    test('selectSupplyPlan updates selected plan and prices', () {
      cubit.selectSupplyPlan(0); // 1 Month plan
      expect(cubit.state.selectedSupplyIndex, 0);
      expect(cubit.state.currentUnitPrice, 1299);
      expect(cubit.state.totalPrice, 1299);

      cubit.selectSupplyPlan(2); // 6 Month plan
      expect(cubit.state.selectedSupplyIndex, 2);
      expect(cubit.state.currentUnitPrice, 4999);
      expect(cubit.state.totalPrice, 4999);
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
        expect(find.text('3 Months'), findsOneWidget);
        expect(find.text('6 Months'), findsOneWidget);

        // Verify initial Add button
        expect(find.text('Add'), findsOneWidget);

        // Switch to 1 Month plan (price = 1299)
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1 Month'));
        await tester.pumpAndSettle();
        expect(find.text('Add'), findsOneWidget);

        // Increment quantity (+ button)
        await tester.tap(find.byIcon(LucideIcons.plus));
        await tester.pumpAndSettle();
        expect(find.text('Add'), findsOneWidget);

        // Verify tabs
        await tester.ensureVisible(find.text('Benefits'));
        expect(find.text('Benefits'), findsOneWidget);
        expect(find.text('Ingredients'), findsOneWidget);
        expect(find.text('How to Use'), findsOneWidget);
        expect(find.text('Clinical Results'), findsOneWidget);
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
        expect(find.text('Add'), findsOneWidget);
        expect(find.byIcon(LucideIcons.minus), findsOneWidget);
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
        expect(find.text('Add'), findsOneWidget);
        expect(find.text('₹2499'), findsWidgets);
      },
    );
  });
}
