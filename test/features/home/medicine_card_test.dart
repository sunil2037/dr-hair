import 'package:dr_hair/features/home/presentation/widgets/medicine_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('MedicineCard', () {
    testWidgets(
      'renders medicine details and Dermatologist badge without add-to-cart button',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MedicineCard(
                title: 'Follicle Revive Serum',
                desc: 'Reduces hair fall by 40%',
                price: '₹1,299',
                imageUrl: 'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=600',
                category: MedicineCategory.dermatologist,
                rating: 4.9,
                showAddToCart: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // Verify text
        expect(find.text('Follicle Revive Serum'), findsOneWidget);
        expect(find.text('Reduces hair fall by 40%'), findsOneWidget);
        expect(find.text('₹1,299'), findsOneWidget);
        expect(find.text('4.9'), findsOneWidget);

        // Verify Dermatologist badge
        expect(find.text('Dermatologist'), findsOneWidget);

        // Verify NO add to cart plus icon
        expect(find.byIcon(LucideIcons.plus), findsNothing);

        // Verify tap callback
        await tester.tap(find.text('Follicle Revive Serum'));
        expect(tapped, true);
      },
    );

    testWidgets('renders Ayurveda badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MedicineCard(
              title: 'Bhringraj Scalp Elixir',
              desc: 'Cold-pressed Ayurvedic root therapy',
              price: '₹849',
              imageUrl: 'https://images.unsplash.com/photo-1617897903246-719242758050?q=80&w=600',
              category: MedicineCategory.ayurveda,
              showAddToCart: false,
            ),
          ),
        ),
      );

      expect(find.text('Ayurveda'), findsOneWidget);
      expect(find.byIcon(LucideIcons.leaf), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsNothing);
    });
  });
}
