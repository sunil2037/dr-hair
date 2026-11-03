import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductRepository _repository;

  ProductsCubit({ProductRepository? repository, ProductsState? initialState})
    : _repository = repository ?? ProductRepositoryImpl(),
      super(initialState ?? ProductsState.initial());

  String? _rootCauseForIndex(int index) {
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
    if (index <= 0 || index >= ids.length) return null;
    return ids[index];
  }

  Future<void> loadProducts({bool refresh = false}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _repository.getProducts(
        rootCause: _rootCauseForIndex(state.selectedCategoryIndex),
        query: state.searchQuery,
      );
      emit(state.copyWith(products: result.items, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              'Unable to load products. Please check your connection.',
        ),
      );
    }
  }

  Future<void> selectCategory(int index) async {
    if (index >= 0 && index != state.selectedCategoryIndex) {
      emit(state.copyWith(selectedCategoryIndex: index));
      await loadProducts(refresh: true);
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(searchQuery: query));
    await loadProducts(refresh: true);
  }

  Future<void> clearSearch() async {
    emit(state.copyWith(searchQuery: ''));
    await loadProducts(refresh: true);
  }
}
