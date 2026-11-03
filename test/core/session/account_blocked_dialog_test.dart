import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/core/session/session_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showAccountBlockedDialog displays warning shield, unblock guidance, and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  SessionCoordinator.instance.showAccountBlockedDialog(
                    context: context,
                    message: 'Your Dr. Hair account has been suspended by clinic administration.',
                    supportPhone: '+91-9876543210',
                    supportEmail: 'support@drhair.in',
                  );
                },
                child: const Text('Trigger Block Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to show dialog
    await tester.tap(find.text('Trigger Block Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog elements
    expect(find.text('Account Suspended'), findsOneWidget);
    expect(find.text('Your Dr. Hair account has been suspended by clinic administration.'), findsOneWidget);
    expect(find.text('How to regain access & unblock:'), findsOneWidget);
    expect(find.text('+91-9876543210'), findsOneWidget);
    expect(find.text('support@drhair.in'), findsOneWidget);
    expect(find.text('Call Support'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
