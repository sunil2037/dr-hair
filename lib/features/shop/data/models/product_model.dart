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
  final String rootCause;
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
    this.rootCause = 'Hair',
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
      rootCause: 'Hair',
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
      rootCause: 'Hair',
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
      rootCause: 'Hair',
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
      rootCause: 'Dandruff',
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
    ProductItem(
      id: 'anti-dandruff-scalp-lotion',
      name: 'Anti-Dandruff Clarifying Lotion',
      subtitle: 'Salicylic Acid 2% + Tea Tree & Piroctone Olamine Night Care',
      category: 'Dermatologist Formulation',
      rootCause: 'Dandruff',
      rating: 4.85,
      reviewsCount: 620,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '100ml Scalp Applicator',
          price: 649,
          mrp: 899,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '300ml Intensive Pack',
          price: 1599,
          mrp: 2399,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Dissolves Flakes & Sebum Plugs',
          description: 'Salicylic acid gently breaks down stubborn dead scalp flakes and sebum plugs.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Piroctone Olamine & Tea Tree',
          concentration: '1.5%',
          purpose: 'Soothes persistent scalp itch and prevents Malassezia recurrence.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Direct Application',
          description:
              'Apply directly onto scalp sections at night 3 times a week.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '94%',
          claim: 'Flake-free scalp maintenance over 8 weeks',
          source: 'Dermatology clinical log',
        ),
      ],
    ),
    ProductItem(
      id: 'gut-health-probiotics',
      name: 'Gut Health Probiotics & Enzymes',
      subtitle:
          '15 Billion CFU Multi-Strain Probiotics for Nutrient Absorption',
      category: 'Clinical Nutrition',
      rootCause: 'Gut',
      rating: 4.88,
      reviewsCount: 780,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '60 Delayed-Release Caps',
          price: 799,
          mrp: 1099,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '180 Delayed-Release Caps',
          price: 1999,
          mrp: 2999,
          badge: 'BEST VALUE',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Enhances Micro-Nutrient Uptake',
          description: 'Restores healthy intestinal flora to allow optimal absorption of iron, zinc, and biotin for follicles.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Lactospore & Digestive Enzymes',
          concentration: '15 Billion CFU',
          purpose: 'Spore-forming shelf-stable probiotics that survive gastric acid to nourish the gut lining.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Morning Dose',
          description:
              'Take 1 capsule on an empty stomach 30 mins before breakfast.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '91%',
          claim: 'Noticed improved digestion and less systemic gut bloating',
          source: 'Clinical digestion study',
        ),
      ],
    ),
    ProductItem(
      id: 'triphala-gut-elixir',
      name: 'Ayurvedic Triphala Detox Elixir',
      subtitle:
          'Cold-Pressed Amla, Haritaki & Bibhitaki for Gut Agni & Cleansing',
      category: 'Ayurvedic Therapy',
      rootCause: 'Gut',
      rating: 4.82,
      reviewsCount: 510,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1617897903246-719242758050?q=80&w=800',
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '500ml Pure Juice',
          price: 549,
          mrp: 799,
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Pacifies Pitta & Clears Toxins (Ama)',
          description: 'Supports regular elimination to stop internal heat buildup that triggers sudden root shedding.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Certified Organic Triphala',
          concentration: '100% Herbal',
          purpose: 'Traditional botanical blend balancing digestive fire and metabolism.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Dilute in Warm Water',
          description: 'Mix 20ml in a glass of warm water before bedtime.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '88%',
          claim: 'Improved bowel regularity within 10 days',
          source: 'Ayurvedic wellness assessment',
        ),
      ],
    ),
    ProductItem(
      id: 'ashwagandha-calm-complex',
      name: 'Calm & Sleep Ashwagandha KSM-66',
      subtitle: 'Cortisol Reducer & Stress Recovery for Telogen Effluvium',
      category: 'Ayurvedic Therapy',
      rootCause: 'Stress',
      rating: 4.92,
      reviewsCount: 1340,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '60 Full-Spectrum Tablets',
          price: 849,
          mrp: 1199,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '180 Full-Spectrum Tablets',
          price: 2199,
          mrp: 3299,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Mitigates Stress-Induced Hair Loss',
          description: 'Significantly reduces circulating serum cortisol levels that prematurely shift hair follicles into telogen phase.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'KSM-66 Ashwagandha Root',
          concentration: '600mg (5% Withanolides)',
          purpose: 'Gold standard organic root adaptogen for neuro-endocrine relaxation.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Night Administration',
          description: 'Take 1 tablet after dinner with warm water or milk.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '27.9%',
          claim: 'Reduction in serum cortisol levels',
          source: 'Randomized, double-blind clinical trial',
        ),
      ],
    ),
    ProductItem(
      id: 'shiro-abhyanga-calming-oil',
      name: 'Brahmi & Shankhpushpi Shiro-Oil',
      subtitle: 'Ayurvedic Cooling Scalp Therapy for Stress & Sleep Support',
      category: 'Ayurvedic Therapy',
      rootCause: 'Stress',
      rating: 4.86,
      reviewsCount: 670,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1617897903246-719242758050?q=80&w=800',
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '100ml Glass Dropper',
          price: 699,
          mrp: 950,
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Soothes Neural Receptors',
          description: 'Cooling botanical infusion induces tranquil sleep and relieves chronic scalp tension.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Brahmi & Shankhpushpi',
          concentration: 'Traditional Kashaya',
          purpose: 'Potent Medhya herbs known to calm nervous exhaustion.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Gentle Scalp Press',
          description:
              'Apply 5-8 drops on crown chakra and temples before bed.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '92%',
          claim: 'Reported deeper, uninterrupted sleep quality',
          source: 'Ayurvedic clinical survey',
        ),
      ],
    ),
    ProductItem(
      id: 'thyro-balance-herbal-complex',
      name: 'Thyro-Balance Metabolism Support',
      subtitle: 'Kanchnar Guggul + Selenium & Iodine Metabolic Formula',
      category: 'Ayurvedic Therapy',
      rootCause: 'Thyroid',
      rating: 4.89,
      reviewsCount: 890,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '60 Ayurvedic Tablets',
          price: 899,
          mrp: 1299,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '180 Ayurvedic Tablets',
          price: 2399,
          mrp: 3599,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Re-energizes Sluggish Follicle Metabolism',
          description: 'Addresses sluggish cellular turnover and diffuse hair thinning caused by sub-optimal thyroid hormone balance.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Kanchnar Guggul & Selenium',
          concentration: '550mg Complex',
          purpose: 'Classical glandular balancer combined with essential thyroid trace minerals.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Twice Daily',
          description: 'Take 1 tablet after breakfast and 1 after dinner with warm water.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '87%',
          claim: 'Reported reduced lethargy and lower dry scalp shedding',
          source: 'Endocrine wellness follow-up',
        ),
      ],
    ),
    ProductItem(
      id: 'pcos-inositol-hormone-balance',
      name: 'PCOS Care & Inositol Complex',
      subtitle: '40:1 Myo-Inositol & D-Chiro-Inositol with Shatavari & Zinc',
      category: 'Clinical Nutrition',
      rootCause: 'PCOS',
      rating: 4.93,
      reviewsCount: 1120,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '30 Sachets Powder Drink',
          price: 999,
          mrp: 1499,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '90 Sachets Powder Drink',
          price: 2599,
          mrp: 4199,
          badge: 'BEST VALUE',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Manages Ovarian Androgen Spikes',
          description: 'Normalizes insulin sensitivity and stops excess free testosterone from causing female androgenic alopecia and hair thinning.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Myo-Inositol : D-Chiro-Inositol (40:1)',
          concentration: '2000mg : 50mg',
          purpose: 'Clinically proven physiological ratio to restore hormonal ovulation and hair density.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Daily Drink Mix',
          description: 'Mix 1 sachet in 200ml cold water and drink 30 mins before breakfast.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '91%',
          claim: 'Significant reduction in facial hirsutism and crown widening',
          source: 'PCOS clinical trial registry',
        ),
      ],
    ),
    ProductItem(
      id: 'dht-blocker-max-capsules',
      name: 'Max DHT Blocker & Saw Palmetto',
      subtitle:
          'Standardized Saw Palmetto 500mg, Beta-Sitosterol & Stinging Nettle',
      category: 'Clinical Nutrition',
      rootCause: 'Hormone',
      rating: 4.91,
      reviewsCount: 1540,
      inStock: true,
      images: [
        'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=800',
      ],
      supplyPlans: [
        ProductSupplyPlan(
          title: '1 Month',
          subtitle: '60 Veg Capsules',
          price: 1099,
          mrp: 1599,
        ),
        ProductSupplyPlan(
          title: '3 Months',
          subtitle: '180 Veg Capsules',
          price: 2799,
          mrp: 4499,
          badge: 'MOST POPULAR',
        ),
      ],
      benefits: [
        ProductBenefitItem(
          title: 'Blocks 5-Alpha Reductase Internally',
          description: 'Prevents systemic DHT from binding to androgen-sensitive scalp receptors on the crown and temples.',
        ),
      ],
      ingredients: [
        ProductIngredientItem(
          name: 'Saw Palmetto & Beta-Sitosterol',
          concentration: '500mg (85% Fatty Acids)',
          purpose: 'Natural herbal 5-AR enzyme blocker protecting genetically sensitive hair follicles.',
        ),
      ],
      usageSteps: [
        ProductUsageStep(
          step: 1,
          title: 'Post Lunch Dose',
          description: 'Take 2 capsules daily post-lunch with water.',
        ),
      ],
      clinicalMetrics: [
        ProductClinicalMetric(
          percentage: '89%',
          claim: 'Arrested temple and vertex miniaturization within 90 days',
          source: 'Androgenic hair loss clinical trial',
        ),
      ],
    ),
  ];

  static ProductItem get defaultProduct => demoCatalog.first;

  static List<ProductItem> getSuggestedProducts(String currentProductId) {
    return demoCatalog.where((p) => p.id != currentProductId).toList();
  }
}
