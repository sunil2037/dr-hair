import 'package:dr_hair/features/shell/presentation/widgets/shell_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('selects tabs through the shell navigation bar',
      (tester) async {
    int selectedIndex = 0;
    bool actionPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ShellBottomNavBar(
              currentIndex: selectedIndex,
              onTabSelected: (index) => selectedIndex = index,
              onActionPressed: () => actionPressed = true,
            ),
          ),
        ),
      ),
    );

    // Tap Videos tab by icon
    await tester.tap(find.byIcon(LucideIcons.circlePlay));
    expect(selectedIndex, 2);

    // Tap AI Action button on the right
    await tester.tap(find.byTooltip('AI Hair Analysis'));
    expect(actionPressed, true);
  });

  testWidgets('renders and handles taps on cart summary bar', (tester) async {
    int cartPressedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ShellBottomNavBar(
              currentIndex: 0,
              cartItemCount: 2,
              cartSubtotal: 1499,
              onTabSelected: (_) {},
              onCartPressed: () => cartPressedCount++,
            ),
          ),
        ),
      ),
    );

    // Ensure cart bar renders
    expect(find.byKey(const ValueKey('cart-summary')), findsOneWidget);
    expect(find.text('2 items · ₹1499'), findsOneWidget);
    expect(find.text('Tap to review & checkout'), findsOneWidget);
    expect(find.text('View Cart'), findsOneWidget);

    // Tap View Cart button directly
    await tester.tap(find.text('View Cart'));
    expect(cartPressedCount, 1);

    // Tap somewhere else on the cart bar
    await tester.tap(find.text('2 items · ₹1499'));
    expect(cartPressedCount, 2);
  });

  testWidgets('hides cart summary bar when cart is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ShellBottomNavBar(
              currentIndex: 0,
              cartItemCount: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('cart-summary')), findsNothing);
    expect(find.byKey(const ValueKey('cart-summary-hidden')), findsOneWidget);
  });
}
