import 'package:dr_hair/features/shop/presentation/views/cart_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('CartView Tests', () {
    testWidgets('applies the FIRSTDR cart reward', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CartView()));

      await tester.enterText(find.byType(TextField), 'FIRSTDR');
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FIRSTDR applied. ₹200 saved.'), findsOneWidget);
      expect(find.text('₹1'), findsNothing);
      expect(find.text('₹1848'), findsWidgets);
    });

    testWidgets(
      'renders empty state with SearchWithCross icon when cart is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CartView(initialItems: [])),
        );

        // Verify empty state text
        expect(find.text('Your Cart is Empty'), findsOneWidget);
        expect(
          find.textContaining('haven\'t added any hair treatments yet'),
          findsOneWidget,
        );

        // Verify empty state asset image
        final imageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/icons/SearchWithCross.png',
        );
        expect(imageFinder, findsOneWidget);

        // Verify action buttons
        expect(find.text('Explore Treatments'), findsOneWidget);
        expect(find.text('Reset Demo Cart Items'), findsOneWidget);

        // Reset items restores cart
        await tester.tap(find.text('Reset Demo Cart Items'));
        await tester.pumpAndSettle();

        expect(find.text('Follicle Booster Serum'), findsOneWidget);
        expect(find.text('Your Cart is Empty'), findsNothing);
      },
    );

    testWidgets('clear cart empties without showing an undo toast', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CartView()));

      expect(find.text('Follicle Booster Serum'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Cart is now empty
      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('UNDO'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('quantity increment and decrement updates total', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CartView()));

      // Initial subtotal = 1299 + 749 = 2048
      expect(find.text('₹2048'), findsWidgets);

      // Increment quantity of first item
      final plusButtons = find.byIcon(LucideIcons.plus);
      await tester.tap(plusButtons.first);
      await tester.pumpAndSettle();

      // New subtotal = 1299*2 + 749 = 3347
      expect(find.text('₹3347'), findsWidgets);

      // Decrement back
      final minusButtons = find.byIcon(LucideIcons.minus);
      await tester.tap(minusButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('₹2048'), findsWidgets);
    });

    testWidgets('removing item updates cart without a toast', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CartView()));

      final trashButtons = find.byIcon(LucideIcons.trash2);
      expect(trashButtons, findsWidgets);

      // Remove the first item
      await tester.tap(trashButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('UNDO'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      // Only 1 item remains: 749
      expect(find.text('₹749'), findsWidgets);
      expect(find.text('Follicle Booster Serum'), findsNothing);
    });
  });
}
