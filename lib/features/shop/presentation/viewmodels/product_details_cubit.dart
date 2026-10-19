import 'package:flutter_bloc/flutter_bloc.dart';

import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit({
    ProductItem? initialProduct,
    ProductDetailsState? initialState,
  }) : super(
         initialState ?? ProductDetailsState.initial(product: initialProduct),
       );

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

  void toggleFavorite() {
    emit(state.copyWith(isFavorite: !state.isFavorite));
  }

  void selectTab(int index) {
    emit(state.copyWith(activeTab: index));
  }

  void addToCart() {
    emit(state.copyWith(isAddedToCart: true));
  }

  void setFullscreen(bool isOpen) {
    emit(state.copyWith(isFullscreenOpen: isOpen));
  }
}
