import 'package:flutter/foundation.dart';

@immutable
class ProductSupplyPlan {
  final String title;
  final String subtitle;
  final int price;
  final int mrp;
  final String? badge;

  const ProductSupplyPlan({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.mrp,
    this.badge,
  });
}

@immutable
class ProductBenefitItem {
  final String title;
  final String description;

  const ProductBenefitItem({required this.title, required this.description});
}

@immutable
class ProductIngredientItem {
  final String name;
  final String concentration;
  final String purpose;

  const ProductIngredientItem({
    required this.name,
    required this.concentration,
    required this.purpose,
  });
}

@immutable
class ProductUsageStep {
  final int step;
  final String title;
  final String description;

  const ProductUsageStep({
    required this.step,
    required this.title,
    required this.description,
  });
}

@immutable
class ProductClinicalMetric {
  final String percentage;
  final String claim;
  final String source;

  const ProductClinicalMetric({
    required this.percentage,
    required this.claim,
    required this.source,
  });
}

@immutable
class ProductItem {
  final String id;
  final String name;
  final String subtitle;
  final String category;
  final double rating;
  final int reviewsCount;
  final bool inStock;
  final List<String> images;
  final List<ProductSupplyPlan> supplyPlans;
  final List<ProductBenefitItem> benefits;
  final List<ProductIngredientItem> ingredients;
  final List<ProductUsageStep> usageSteps;
  final List<ProductClinicalMetric> clinicalMetrics;

  const ProductItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.inStock,
    required this.images,
    required this.supplyPlans,
    required this.benefits,
    required this.ingredients,
    required this.usageSteps,
    required this.clinicalMetrics,
  });

  /// Curated demo catalog of realistic Dr Hair treatments
  static const List<ProductItem> demoCatalog = [
    ProductItem(
      id: 'follicle-booster-serum',
      name: 'Follicle Booster Serum',
      subtitle: 'Advance Density Complex with 5% Procapil & 3% Redensyl',
      category: 'Dermatologist Formulation',
      rating: 4.9,
      reviewsCount: 1420,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '30ml Serum Bottle',
          price: 1299,
          mrp: 1699,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '60ml + Scalp Roller',
          price: 2799,
          mrp: 3899,
          badge: 'MOST POPULAR',
        ),
        ProductSupplyPlan(
          title: '6 Months',
          subtitle: 'Full Regrowth Protocol',
          price: 4999,
          mrp: 7599,
          badge: 'BEST VALUE',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Reactivates Dormant Follicles',
          description: 'Stimulates cellular activity at the hair matrix to trigger the anagen growth cycle.',
        ),
        ProductBenefitItem(
          title: 'Reduces Excessive Shedding',
          description: 'Anchors roots firmly by strengthening the connective tissue sheath.',
        ),
        ProductBenefitItem(
          title: 'Enhances Shaft Density',
          description: 'Increases hair thickness and diameter over 90 days of consistent use.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Redensyl',
          concentration: '3.0%',
          purpose: 'Targets hair follicle stem cells to reactivate hair division and renewal.',
        ),
        ProductIngredientItem(
          name: 'Procapil',
          concentration: '5.0%',
          purpose: 'Fights follicle aging process and blocks localized DHT synthesis.',
        ),
        ProductIngredientItem(
          name: 'Anagain',
          concentration: '4.0%',
          purpose: 'Stimulates specific signal molecules in the dermal papilla to initiate growth.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Cleanse & Dry',
          description: 'Ensure your scalp is clean and completely dry before application.',
        ),
        ProductUsageStep(
          step: 2,
          title: 'Target Application',
          description: 'Dispense 1ml directly onto the affected scalp zones using the dropper.',
        ),
        ProductUsageStep(
          step: 3,
          title: 'Gentle Massage',
          description: 'Massage gently in circular motions for 2 minutes. Leave on overnight.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '89%',
          claim: 'Reduction in shedding within 60 days',
          source: 'Double-blind 12-week dermatological study',
        ),
        ProductClinicalMetric(
          percentage: '94%',
          claim: 'Reported thicker, fuller hair shaft diameter',
          source: 'Independent trichology evaluation',
        ),
        ProductClinicalMetric(
          percentage: '2.1x',
          claim: 'Increase in anagen to telogen hair ratio',
          source: 'Digital phototrichogram trial',
        ),
      ],
    ),
    ProductItem(
      id: 'biotin-growth-complex',
      name: 'Biotin Growth Complex',
      subtitle: 'DHT Blocker & Keratin Fortification Oral Supplements',
      category: 'Clinical Nutrition',
      rating: 4.8,
      reviewsCount: 980,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '60 Veg Capsules',
          price: 999,
          mrp: 1399,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '180 Veg Capsules',
          price: 2499,
          mrp: 3599,
          badge: 'MOST POPULAR',
        ),
        ProductSupplyPlan(
          title: '6 Months',
          subtitle: '360 Veg Capsules',
          price: 4299,
          mrp: 6999,
          badge: 'BEST VALUE',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Internal Follicle Nutrition',
          description: 'Supplies bio-available keratin building blocks directly to hair roots.',
        ),
        ProductBenefitItem(
          title: 'Natural DHT Blocker',
          description: 'Saw palmetto and beta-sitosterol help reduce 5-alpha reductase activity.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'D-Biotin',
          concentration: '10,000 mcg',
          purpose:
              'Essential coenzyme for keratin synthesis and cellular turnover.',
        ),
        ProductIngredientItem(
          name: 'Saw Palmetto',
          concentration: '320 mg',
          purpose: 'Inhibits enzymatic conversion of testosterone to DHT.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Daily Capsule',
          description: 'Take 2 capsules daily after breakfast with a full glass of water.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '86%',
          claim: 'Reported improved hair resilience and reduced breakage',
          source: '90-day patient survey',
        ),
      ],
    ),
    ProductItem(
      id: 'bhringraj-scalp-elixir',
      name: 'Bhringraj Scalp Elixir',
      subtitle: 'Cold-Pressed Ayurvedic Root Therapy with 16 Botanicals',
      category: 'Ayurvedic Therapy',
      rating: 4.9,
      reviewsCount: 1150,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1617897903246-719242758050?q=80&w=800',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '100ml Glass Bottle',
          price: 849,
          mrp: 1199,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '300ml Therapy Pack',
          price: 2199,
          mrp: 3299,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Scalp Microcirculation',
          description: 'Stimulates root-level blood flow and calms Pitta dosha scalp heat.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Keshraj Bhringraj',
          concentration: 'Pure Extract',
          purpose: 'Revered ancient herb known as king of hair rejuvenation.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Warm & Apply',
          description: 'Warm a few drops between palms and gently massage roots 2x weekly.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '91%',
          claim: 'Noticed significantly deeper scalp nourishment and shine',
          source: 'Ayurvedic clinical observations',
        ),
      ],
    ),
    ProductItem(
      id: 'scalp-detox-shampoo',
      name: 'Clinical Scalp Detox Shampoo',
      subtitle: 'Ketoconazole 2% & Zinc Pyrithione Anti-Dandruff Wash',
      category: 'Dermatologist Formulation',
      rating: 4.7,
      reviewsCount: 840,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '200ml Bottle',
          price: 749,
          mrp: 999,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '600ml Value Pack',
          price: 1899,
          mrp: 2699,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Clears Dandruff & Fungal Buildup',
          description: 'Eliminates Malassezia furfur and clarifies blocked follicle pores.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Ketoconazole',
          concentration: '2.0%',
          purpose:
              'Clinical antifungal agent that stops scalp flakes and itch.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Lather & Wait',
          description: 'Apply to wet hair, lather well, and leave on for 3 minutes before rinsing.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '96%',
          claim: 'Fungus and itch clearance within 14 days of use',
          source: 'Clinical scalp swab evaluation',
        ),
      ],
    ),
  ];

  static ProductItem get defaultProduct => demoCatalog.first;

  static List<ProductItem> getSuggestedProducts(String currentProductId) {
    return demoCatalog.where((p) => p.id != currentProductId).toList();
  }
}
