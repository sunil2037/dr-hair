import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dr_hair/features/static/data/policy_content.dart';
import 'package:dr_hair/features/static/domain/policy_models.dart';
import 'package:dr_hair/features/static/presentation/views/policy_page_view.dart';

void main() {
  group('PolicyPageView Tests', () {
    Widget buildPolicyApp({PolicyType initialType = PolicyType.privacyPolicy}) {
      return MaterialApp(
        home: PolicyPageView(initialType: initialType),
      );
    }

    testWidgets('renders Privacy Policy with DPDP Act 2023 disclosures and pending approval notice', (tester) async {
      await tester.pumpWidget(buildPolicyApp(initialType: PolicyType.privacyPolicy));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('Pending Business / Legal Approval'), findsOneWidget);
      expect(find.textContaining('Digital Personal Data Protection (DPDP) Act, 2023'), findsOneWidget);
      expect(find.text('1. Standalone DPDP Notice & Overview'), findsOneWidget);
      expect(find.text('2. Personal Data We Collect'), findsOneWidget);
      expect(find.text('7. Grievance Redressal Officer'), findsOneWidget);
    });

    testWidgets('switches between policies using tabs', (tester) async {
      await tester.pumpWidget(buildPolicyApp(initialType: PolicyType.privacyPolicy));
      await tester.pumpAndSettle();

      // Tap Terms chip
      expect(find.text('Terms'), findsOneWidget);
      await tester.tap(find.text('Terms'));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsWidgets);
      expect(find.text('1. Clinical & Medical Disclaimer'), findsOneWidget);

      // Tap Returns & Refunds chip
      expect(find.text('Returns & Refunds'), findsOneWidget);
      await tester.tap(find.text('Returns & Refunds'));
      await tester.pumpAndSettle();

      expect(find.text('Returns & Refunds Policy'), findsWidgets);
      expect(find.text('1. Hygiene & Seal Restrictions'), findsOneWidget);

      // Tap Guarantee chip
      expect(find.text('Guarantee'), findsOneWidget);
      await tester.tap(find.text('Guarantee'));
      await tester.pumpAndSettle();

      expect(find.text('Money-Back Guarantee'), findsWidgets);
      expect(find.text('1. Status: Under Business & Legal Review'), findsOneWidget);
      expect(find.textContaining('POLICY DETAILS PENDING FORMAL BUSINESS & LEGAL APPROVAL'), findsOneWidget);
    });

    testWidgets('PolicyRepository contains valid structured content for all policy types', (tester) async {
      for (final type in PolicyType.values) {
        final policy = PolicyRepository.getPolicy(type);
        expect(policy.title.isNotEmpty, isTrue);
        expect(policy.summary.isNotEmpty, isTrue);
        expect(policy.sections.isNotEmpty, isTrue);
        expect(policy.lastUpdated.isNotEmpty, isTrue);
      }
    });
  });
}
