import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/shop/presentation/views/checkout_view.dart';

void main() {
  group('CheckoutView Demo Behavior & Policy Links Tests', () {
    Widget createTestApp() {
      return const MaterialApp(
        home: CheckoutView(amount: 2048),
      );
    }

    testWidgets('renders delivery required, payment provider note, and order breakdown', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('DELIVERY ADDRESS'), findsOneWidget);
      expect(find.text('Delivery address required'), findsOneWidget);
      expect(find.text('PAYMENT METHOD'), findsOneWidget);
      expect(find.text('Payment provider connection required to continue'), findsOneWidget);
      expect(find.text('Items Total'), findsOneWidget);
      expect(find.text('₹2048'), findsWidgets);
    });

    testWidgets('displays demo checkout transparency note and never claims payment success', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Demo Checkout: Live payment processor'), findsOneWidget);
      expect(find.textContaining('Payment setup required'), findsOneWidget);

      // Tap Place Order button
      await tester.tap(find.textContaining('Payment setup required'));
      await tester.pumpAndSettle();

      expect(
        find.text('Checkout is unavailable until address, order, and payment services are connected.'),
        findsOneWidget,
      );
    });

    testWidgets('renders clickable policy links for Terms, Privacy, and Returns', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Returns & Refunds'), findsOneWidget);
    });
  });
}
