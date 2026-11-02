import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductRepository _repository;

  ProductsCubit({
    ProductRepository? repository,
    ProductsState? initialState,
  })  : _repository = repository ?? ProductRepositoryImpl(),
        super(initialState ?? ProductsState.initial());

  Future<void> loadProducts({bool refresh = false}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _repository.getProducts();
      emit(state.copyWith(
        products: result.items.isNotEmpty ? result.items : state.products,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load products. Please check your connection.',
      ));
    }
  }

  void selectCategory(int index) {
    if (index >= 0 && index != state.selectedCategoryIndex) {
      emit(state.copyWith(selectedCategoryIndex: index));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }
}
