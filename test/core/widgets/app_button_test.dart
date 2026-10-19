import 'package:dr_hair/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton renders text and triggers callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              text: 'Click Me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
    await tester.tap(find.text('Click Me'));
    expect(tapped, true);
  });

  testWidgets('AppButton respects disabled state', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              text: 'Disabled Button',
              isDisabled: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Disabled Button'));
    expect(tapped, false);
  });

  testWidgets('AppButton displays loading indicator when isLoading is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              text: 'Loading Button',
              isLoading: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Button'), findsNothing);
  });

  testWidgets('AppButton supports outlined and tonal variants', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                text: 'Outlined',
                variant: AppButtonVariant.outlined,
              ),
              AppButton(
                text: 'Tonal',
                variant: AppButtonVariant.tonal,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Outlined'), findsOneWidget);
    expect(find.text('Tonal'), findsOneWidget);
  });
}
