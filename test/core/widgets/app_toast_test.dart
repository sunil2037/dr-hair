import 'package:dr_hair/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('replaces the current message and dismisses it quickly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => AppToast.show(
                    context,
                    const SnackBar(content: Text('First message')),
                  ),
                  child: const Text('Show first'),
                ),
                TextButton(
                  onPressed: () => AppToast.show(
                    context,
                    const SnackBar(content: Text('Second message')),
                  ),
                  child: const Text('Show second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show first'));
    await tester.pump();
    expect(find.text('First message'), findsOneWidget);

    await tester.tap(find.text('Show second'));
    await tester.pump();
    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Second message'), findsNothing);
  });
}
