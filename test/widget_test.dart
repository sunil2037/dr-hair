import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/main.dart';

void main() {
  testWidgets('App renders Dr Hair smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
