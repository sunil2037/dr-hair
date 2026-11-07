import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final ProductRepository _repository;
  final String? _initialProductId;

  ProductDetailsCubit({
    ProductItem? initialProduct,
    String? productId,
    ProductRepository? repository,
    ProductDetailsState? initialState,
  })  : _repository = repository ?? ProductRepositoryImpl(),
        _initialProductId = productId ?? initialProduct?.id,
        super(
          initialState ??
              ProductDetailsState.initial(
                product: initialProduct,
                isLoading: initialProduct == null && productId != null,
              ),
        ) {
    if (initialProduct == null && productId != null && productId.isNotEmpty) {
      loadProduct(productId);
    }
  }

  /// Pull-to-refresh / slide-to-refresh handler for product details.
  Future<void> refreshProduct() async {
    final targetId = state.product.id.isNotEmpty ? state.product.id : _initialProductId;
    if (targetId == null || targetId.isEmpty) return;
    try {
      final product = await _repository.getProductById(targetId);
      if (product != null) {
        ProductItem.cacheProducts([product]);
        emit(state.copyWith(
          product: product,
          isLoading: false,
          isNotFound: false,
        ));
      }
    } catch (_) {
      // Gracefully preserve existing loaded state on network hiccups
    }
  }

  Future<void> loadProduct(String productId) async {
    emit(state.copyWith(isLoading: true, isNotFound: false));
    try {
      final product = await _repository.getProductById(productId);
      if (product != null) {
        ProductItem.cacheProducts([product]);
        emit(state.copyWith(
          product: product,
          isLoading: false,
          isNotFound: false,
          selectedSupplyIndex: product.supplyPlans.length > 1 ? 1 : 0,
        ));
      } else {
        emit(state.copyWith(isLoading: false, isNotFound: true));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false, isNotFound: true));
    }
  }

  void selectImage(int index) {
    if (index >= 0 && index < state.images.length) {
      emit(state.copyWith(activeImageIndex: index));
    }
  }

  void selectSupplyPlan(int index) {
    if (index >= 0 && index < state.supplyPlans.length) {
      emit(state.copyWith(selectedSupplyIndex: index));
    }
  }

  void incrementQuantity() {
    if (state.quantity < 10) {
      emit(state.copyWith(quantity: state.quantity + 1));
    }
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      emit(state.copyWith(quantity: state.quantity - 1));
    }
  }

  void setQuantity(int quantity) {
    final next = quantity.clamp(1, 10).toInt();
    if (next != state.quantity) {
      emit(state.copyWith(quantity: next));
    }
  }

  void toggleFavorite() {
    emit(state.copyWith(isFavorite: !state.isFavorite));
  }

  void selectTab(int index) {
    emit(state.copyWith(activeTab: index));
  }

  void addToCart() {
    emit(state.copyWith(isAddedToCart: true));
  }

  void removeFromCart() {
    emit(state.copyWith(isAddedToCart: false, quantity: 1));
  }

  void setFullscreen(bool isOpen) {
    emit(state.copyWith(isFullscreenOpen: isOpen));
  }
}
