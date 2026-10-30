import 'package:flutter/foundation.dart';

enum CouponDiscountType { fixed, percent }

@immutable
class CouponRule {
  final String code;
  final CouponDiscountType discountType;
  final int discountValue;
  final String appliesTo;
  final int minimumOrder;
  final int uses;
  final int maxUses;
  final DateTime expiresOn;
  final bool isActive;

  const CouponRule({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.appliesTo,
    required this.minimumOrder,
    required this.uses,
    required this.maxUses,
    required this.expiresOn,
    required this.isActive,
  });

  CouponEvaluation evaluate({
    required int subtotal,
    required List<Map<String, dynamic>> items,
    DateTime? now,
    bool isFirstOrder = false,
  }) {
    final currentDate = now ?? DateTime.now();
    if (!isActive) {
      return const CouponEvaluation.invalid('This coupon is paused.');
    }
    if (DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    ).isAfter(DateTime(expiresOn.year, expiresOn.month, expiresOn.day))) {
      return const CouponEvaluation.invalid('This coupon has expired.');
    }
    if (uses >= maxUses) {
      return const CouponEvaluation.invalid(
        'This coupon has reached its redemption limit.',
      );
    }
    if (subtotal < minimumOrder) {
      return CouponEvaluation.invalid(
        'Add items worth ₹$minimumOrder to use this coupon.',
      );
    }
    if (appliesTo == 'First order' && !isFirstOrder) {
      return const CouponEvaluation.invalid(
        'Sign in to check first-order coupon eligibility.',
      );
    }

    var eligibleSubtotal = subtotal;
    if (appliesTo != 'All products' && appliesTo != 'First order') {
      eligibleSubtotal = items.fold<int>(0, (sum, item) {
        final title = (item['title'] as String? ?? '').toLowerCase();
        if (!title.contains(appliesTo.toLowerCase())) return sum;
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        return sum + (price * quantity);
      });
      if (eligibleSubtotal == 0) {
        return CouponEvaluation.invalid(
          'This coupon applies to $appliesTo only.',
        );
      }
    }

    final discount = discountType == CouponDiscountType.percent
        ? (eligibleSubtotal * discountValue / 100).round()
        : discountValue;
    return CouponEvaluation.valid(discount.clamp(0, eligibleSubtotal).toInt());
  }
}

@immutable
class CouponEvaluation {
  final bool isValid;
  final int discount;
  final String message;

  const CouponEvaluation._({
    required this.isValid,
    this.discount = 0,
    this.message = '',
  });

  const CouponEvaluation.valid(int amount)
    : this._(isValid: true, discount: amount, message: 'Coupon applied.');

  const CouponEvaluation.invalid(String reason)
    : this._(isValid: false, message: reason);
}

/// Demo-only rules mirror the Commerce coupon examples until a shared coupon API exists.
final List<CouponRule> demoCouponRules = [
  CouponRule(
    code: 'FIRSTDR',
    discountType: CouponDiscountType.fixed,
    discountValue: 200,
    appliesTo: 'All products',
    minimumOrder: 999,
    uses: 0,
    maxUses: 2500,
    expiresOn: DateTime(2026, 12, 31),
    isActive: true,
  ),
  CouponRule(
    code: 'GROW15',
    discountType: CouponDiscountType.percent,
    discountValue: 15,
    appliesTo: 'All products',
    minimumOrder: 999,
    uses: 284,
    maxUses: 600,
    expiresOn: DateTime(2026, 12, 31),
    isActive: true,
  ),
  CouponRule(
    code: 'SERUM300',
    discountType: CouponDiscountType.fixed,
    discountValue: 300,
    appliesTo: 'Follicle Booster Serum',
    minimumOrder: 2000,
    uses: 118,
    maxUses: 250,
    expiresOn: DateTime(2026, 11, 30),
    isActive: true,
  ),
];
