import 'package:dr_hair/features/videos/presentation/views/videos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VideosView renders header and filters with NestedScrollView',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VideosView(),
      ),
    );

    expect(find.text('Patient Video Stories'), findsOneWidget);
    expect(find.text('100% Verified Outcomes'), findsOneWidget);

    // Category filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hair Fall'), findsOneWidget);
    expect(find.text('Regrowth'), findsOneWidget);
    expect(find.text('Dandruff'), findsOneWidget);

    // Initial state shows Yashveer Soni
    expect(find.text('Yashveer Soni'), findsOneWidget);

    // Switch filter to Dandruff
    await tester.tap(find.text('Dandruff'));
    await tester.pumpAndSettle();

    // Now Ananya Mehra is visible
    expect(find.text('Ananya Mehra'), findsOneWidget);
    expect(find.text('Yashveer Soni'), findsNothing);
  });
}
