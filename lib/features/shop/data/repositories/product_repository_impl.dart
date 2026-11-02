import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  static final ProductItem _customKitProduct = ProductItem(
    id: 'traya-custom-regrowth-kit',
    name: '3-Month Hair Regrowth Kit',
    subtitle: 'Follicle Booster Serum + Scalp Oil + DHT Blocker Supplements',
    category: 'Doctor & Ayurvedic Regimen',
    rootCause: 'Hair',
    rating: 4.95,
    reviewsCount: 3820,
    inStock: true,
    images: const [
      'https://res.cloudinary.com/demo/image/upload/w_800,c_fill,ar_1:1/samples/ecommerce/leather-bag-gray.jpg',
      'https://images.unsplash.com/photo-1608248597359-5509a5665805?q=80&w=800',
    ],
    supplyPlans: const [
      ProductSupplyPlan(
        title: 'Complete Kit',
        subtitle: 'Serum + Oil + DHT Herbal Capsules',
        price: 1445,
        mrp: 2044,
        badge: 'SAVINGS 29%',
      ),
      ProductSupplyPlan(
        title: '6 Months Protocol',
        subtitle: 'Double Kit + Scalp Dermaroller',
        price: 2699,
        mrp: 4088,
        badge: 'BEST VALUE',
      ),
    ],
    benefits: const [
      ProductBenefitItem(
        title: 'Dual-Science Regimen',
        description: 'Combines dermatological actives with classical Ayurvedic scalp therapy.',
      ),
      ProductBenefitItem(
        title: 'Addresses Root Causes',
        description: 'Actively tackles scalp dandruff, DHT miniaturization, and micro-nutrient deficiencies.',
      ),
    ],
    ingredients: const [
      ProductIngredientItem(
        name: 'Redensyl + Procapil',
        concentration: '8.0% Complex',
        purpose: 'Stem cell follicular reactivation & localized DHT blockage.',
      ),
      ProductIngredientItem(
        name: 'Kshirpak Bhringraj',
        concentration: '100% Ayurvedic',
        purpose: 'Cools scalp, clears follicular inflammation & promotes deep root anchoring.',
      ),
    ],
    usageSteps: const [
      ProductUsageStep(
        step: 1,
        title: 'Apply Follicle Serum',
        description: 'Apply 1ml of serum to clean, dry scalp every morning and massage lightly.',
      ),
      ProductUsageStep(
        step: 2,
        title: 'Scalp Oil Therapy',
        description: 'Apply herbal oil 3 nights a week before bedtime to nourish roots.',
      ),
    ],
    clinicalMetrics: const [
      ProductClinicalMetric(
        percentage: '93%',
        claim: 'saw significant hair shedding reduction',
        source: 'Dr. Hair Clinical Registry Dec 2022',
      ),
    ],
  );

  static List<ProductItem> get fallbackCatalog => [
        _customKitProduct,
        ...ProductItem.demoCatalog,
      ];

  @override
  Future<({List<ProductItem> items, bool hasMore, int total})> getProducts({
    String? category,
    String? rootCause,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchProducts(
        category: category,
        rootCause: rootCause,
        query: query,
        page: page,
        limit: limit,
      );
      if (result.items.isNotEmpty) {
        return result;
      }
    } catch (_) {
      // Gracefully fall back to local seed products if backend is unreachable
    }

    var list = fallbackCatalog;

    if (rootCause != null && rootCause.trim().isNotEmpty && rootCause != 'All' && rootCause != 'all') {
      final target = rootCause.toLowerCase();
      list = list.where((p) {
        final rc = p.rootCause.toLowerCase();
        final cat = p.category.toLowerCase();
        final name = p.name.toLowerCase();
        return rc == target || cat.contains(target) || name.contains(target);
      }).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((p) {
        final name = p.name.toLowerCase();
        final sub = p.subtitle.toLowerCase();
        final ing = p.ingredients.any((i) => i.name.toLowerCase().contains(q));
        return name.contains(q) || sub.contains(q) || ing;
      }).toList();
    }

    return (
      items: list,
      hasMore: false,
      total: list.length,
    );
  }

  @override
  Future<ProductItem?> getProductById(String id) async {
    try {
      final item = await _remoteDataSource.fetchProductById(id);
      if (item != null) return item;
    } catch (_) {}

    return fallbackCatalog.firstWhere(
      (p) => p.id == id,
      orElse: () => fallbackCatalog.first,
    );
  }
}
