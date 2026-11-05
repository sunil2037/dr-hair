import '../../data/models/product_model.dart';

export '../../data/models/product_model.dart'
    show
        ProductSupplyPlan,
        ProductItem,
        ProductBenefitItem,
        ProductIngredientItem,
        ProductUsageStep,
        ProductClinicalMetric;

class ProductDetailsState {
  final ProductItem product;
  final int activeImageIndex;
  final int selectedSupplyIndex;
  final int quantity;
  final bool isFavorite;
  final int activeTab;
  final bool isAddedToCart;
  final bool isFullscreenOpen;
  final bool isLoading;
  final bool isNotFound;

  const ProductDetailsState({
    required this.product,
    this.activeImageIndex = 0,
    this.selectedSupplyIndex = 1,
    this.quantity = 1,
    this.isFavorite = false,
    this.activeTab = 0,
    this.isAddedToCart = false,
    this.isFullscreenOpen = false,
    this.isLoading = false,
    this.isNotFound = false,
  });

  factory ProductDetailsState.initial({
    ProductItem? product,
    bool isLoading = false,
    bool isNotFound = false,
  }) {
    final prod = product ??
        (isLoading || isNotFound ? ProductItem.empty : ProductItem.defaultProduct);
    return ProductDetailsState(
      product: prod,
      selectedSupplyIndex: prod.supplyPlans.length > 1 ? 1 : 0,
      isLoading: isLoading,
      isNotFound: isNotFound,
    );
  }

  List<String> get images => product.images;
  List<ProductSupplyPlan> get supplyPlans => product.supplyPlans;
  ProductSupplyPlan get selectedSupplyPlan => supplyPlans[selectedSupplyIndex];
  int get currentUnitPrice => selectedSupplyPlan.price;
  int get currentUnitMrp => selectedSupplyPlan.mrp;
  int get totalPrice => currentUnitPrice * quantity;
  int get totalSavings => (currentUnitMrp - currentUnitPrice) * quantity;
  int get discountPercentage => currentUnitMrp > 0
      ? (((currentUnitMrp - currentUnitPrice) / currentUnitMrp) * 100).round()
      : 0;

  ProductDetailsState copyWith({
    ProductItem? product,
    int? activeImageIndex,
    int? selectedSupplyIndex,
    int? quantity,
    bool? isFavorite,
    int? activeTab,
    bool? isAddedToCart,
    bool? isFullscreenOpen,
    bool? isLoading,
    bool? isNotFound,
  }) {
    return ProductDetailsState(
      product: product ?? this.product,
      activeImageIndex: activeImageIndex ?? this.activeImageIndex,
      selectedSupplyIndex: selectedSupplyIndex ?? this.selectedSupplyIndex,
      quantity: quantity ?? this.quantity,
      isFavorite: isFavorite ?? this.isFavorite,
      activeTab: activeTab ?? this.activeTab,
      isAddedToCart: isAddedToCart ?? this.isAddedToCart,
      isFullscreenOpen: isFullscreenOpen ?? this.isFullscreenOpen,
      isLoading: isLoading ?? this.isLoading,
      isNotFound: isNotFound ?? this.isNotFound,
    );
  }
}
