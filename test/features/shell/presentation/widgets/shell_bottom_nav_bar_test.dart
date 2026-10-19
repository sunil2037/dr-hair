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
}
