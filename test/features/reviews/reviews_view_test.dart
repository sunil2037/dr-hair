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

    expect(find.text('Patient Stories'), findsOneWidget);
    expect(find.text('Sample testimonials shown for this app demo'), findsOneWidget);

    // Category chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hair Fall'), findsOneWidget);
    expect(find.text('Regrowth'), findsOneWidget);
    expect(find.text('Dandruff'), findsOneWidget);

    // Initial shows Rahul Sharma
    expect(find.text('Rahul Sharma'), findsOneWidget);

    // Switch filter to Dandruff
    await tester.tap(find.text('Dandruff'));
    await tester.pumpAndSettle();

    expect(find.text('Ananya Mehra'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsNothing);
  });
}
