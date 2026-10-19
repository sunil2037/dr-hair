import 'package:dr_hair/features/shop/presentation/views/cart_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('applies the FIRSTDR cart reward', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CartView()),
    );

    await tester.enterText(find.byType(TextField), 'FIRSTDR');
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('FIRSTDR applied. ₹200 saved.'), findsOneWidget);
    expect(find.text('₹1'), findsNothing);
    expect(find.text('₹1848'), findsOneWidget);
  });
}
