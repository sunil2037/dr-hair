import 'package:dr_hair/core/widgets/category_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CategoryFilterBar renders chips and notifies on selection',
      (tester) async {
    int selected = 0;
    final categories = ['All', 'Hair Fall', 'Regrowth', 'Dandruff'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryFilterBar(
            categories: categories,
            selectedIndex: selected,
            onSelected: (index) => selected = index,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hair Fall'), findsOneWidget);
    expect(find.text('Regrowth'), findsOneWidget);
    expect(find.text('Dandruff'), findsOneWidget);

    // Tap on Regrowth
    await tester.tap(find.text('Regrowth'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });
}
