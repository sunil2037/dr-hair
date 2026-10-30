import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/shop/presentation/views/checkout_view.dart';

void main() {
  group('CheckoutView Demo Behavior & Policy Links Tests', () {
    Widget createTestApp() {
      return const MaterialApp(
        home: CheckoutView(),
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
      expect(find.text('₹0'), findsWidgets);
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

    testWidgets('tapping Change opens delivery address sheet, allows selecting and updating address', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Change to open delivery address bottom sheet
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // Bottom sheet header and saved addresses
      expect(find.text('Select Delivery Address'), findsOneWidget);
      expect(find.text('SAVED ADDRESSES'), findsOneWidget);
      expect(find.text('Add New Delivery Address'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
      expect(find.textContaining('Flat 402, Royal Residency'), findsOneWidget);

      // Tap "Deliver to this Address"
      await tester.tap(find.text('Deliver to this Address'));
      await tester.pumpAndSettle();

      // The checkout address card updates with the selected address
      expect(find.text('Delivery address required'), findsNothing);
      expect(find.text('Yashveer Soni'), findsOneWidget);
      expect(find.textContaining('Royal Residency'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      // Tap address card to reopen sheet
      await tester.tap(find.text('Yashveer Soni'));
      await tester.pumpAndSettle();

      expect(find.text('Select Delivery Address'), findsOneWidget);

      // Select WORK address
      await tester.tap(find.text('WORK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deliver to this Address'));
      await tester.pumpAndSettle();

      // Verified WORK address updated on card
      expect(find.text('WORK'), findsOneWidget);
      expect(find.textContaining('World Trade Park'), findsOneWidget);
    });
  });
}
