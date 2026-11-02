import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository_impl.dart';

class ProductsState {
  final List<ProductItem> products;
  final bool isLoading;
  final String? errorMessage;
  final int selectedCategoryIndex;
  final String searchQuery;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategoryIndex = 0,
    this.searchQuery = '',
  });

  factory ProductsState.initial() => ProductsState(
        products: ProductRepositoryImpl.fallbackCatalog,
        isLoading: false,
        selectedCategoryIndex: 0,
        searchQuery: '',
      );

  List<ProductItem> get filteredProducts {
    var list = products;

    // Filter by root cause category (matching ProductsView tab IDs)
    final categoryId = _tabIdForIndex(selectedCategoryIndex);
    if (categoryId != 'all') {
      list = list.where((p) {
        final root = p.rootCause.toLowerCase();
        final cat = p.category.toLowerCase();
        final name = p.name.toLowerCase();
        final sub = p.subtitle.toLowerCase();

        switch (categoryId) {
          case 'hair':
            return root == 'hair' ||
                cat.contains('hair') ||
                name.contains('hair') ||
                name.contains('follicle') ||
                p.id.contains('regrowth') ||
                p.id.contains('serum');
          case 'dandruff':
            return root == 'dandruff' ||
                cat.contains('dandruff') ||
                name.contains('dandruff') ||
                sub.contains('dandruff') ||
                p.id.contains('dandruff') ||
                p.id.contains('detox');
          case 'gut':
            return root == 'gut' ||
                cat.contains('gut') ||
                cat.contains('digest') ||
                name.contains('gut') ||
                name.contains('probiotic') ||
                p.id.contains('gut') ||
                p.id.contains('probiotic');
          case 'stress':
            return root == 'stress' ||
                cat.contains('stress') ||
                name.contains('calm') ||
                name.contains('stress') ||
                name.contains('sleep') ||
                p.id.contains('calm') ||
                p.id.contains('sleep') ||
                p.id.contains('stress');
          case 'thyroid':
            return root == 'thyroid' ||
                cat.contains('thyroid') ||
                name.contains('thyro') ||
                p.id.contains('thyro');
          case 'pcos':
            return root == 'pcos' ||
                cat.contains('pcos') ||
                name.contains('pcos') ||
                p.id.contains('pcos');
          case 'hormone':
            return root == 'hormone' ||
                cat.contains('hormone') ||
                cat.contains('androgen') ||
                name.contains('dht') ||
                p.id.contains('dht');
          default:
            return root == categoryId || cat.contains(categoryId);
        }
      }).toList();
    }

    // Filter by search query across name, subtitle, and ingredients
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final name = p.name.toLowerCase();
        final sub = p.subtitle.toLowerCase();
        final ing = p.ingredients.any((i) => i.name.toLowerCase().contains(q));
        return name.contains(q) || sub.contains(q) || ing;
      }).toList();
    }

    return list;
  }

  static String _tabIdForIndex(int index) {
    const ids = [
      'all',
      'hair',
      'dandruff',
      'gut',
      'stress',
      'thyroid',
      'pcos',
      'hormone',
    ];
    if (index >= 0 && index < ids.length) return ids[index];
    return 'all';
  }

  ProductsState copyWith({
    List<ProductItem>? products,
    bool? isLoading,
    String? errorMessage,
    int? selectedCategoryIndex,
    String? searchQuery,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
