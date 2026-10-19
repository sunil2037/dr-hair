import 'package:dr_hair/features/reviews/presentation/views/reviews_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReviewsView renders rating card and filters with NestedScrollView',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReviewsView(),
      ),
    );

    expect(find.text('Clinical Reviews'), findsOneWidget);
    expect(find.text('10,000+ Verified Stories'), findsOneWidget);

    // Category chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hair Fall'), findsOneWidget);
    expect(find.text('Regrowth'), findsOneWidget);
    expect(find.text('Dandruff'), findsOneWidget);

    // Initial shows Yashveer Soni
    expect(find.text('Yashveer Soni'), findsOneWidget);

    // Switch filter to Dandruff
    await tester.tap(find.text('Dandruff'));
    await tester.pumpAndSettle();

    expect(find.text('Ananya Mehra'), findsOneWidget);
    expect(find.text('Yashveer Soni'), findsNothing);
  });
}
