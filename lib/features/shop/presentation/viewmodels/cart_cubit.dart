import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product_model.dart';

class CartState {
  final List<Map<String, dynamic>> items;

  const CartState({this.items = const []});

  int get itemCount => items.fold(
    0,
    (total, item) => total + ((item['quantity'] as num?)?.toInt() ?? 0),
  );

  int get subtotal => items.fold(
    0,
    (total, item) =>
        total +
        ((item['price'] as num?)?.toInt() ?? 0) *
            ((item['quantity'] as num?)?.toInt() ?? 0),
  );

  CartState copyWith({List<Map<String, dynamic>>? items}) =>
      CartState(items: items ?? this.items);
}

/// App-scoped cart shared by product details, cart, profile and navigation.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  static String lineId(String productId, String planTitle) =>
      '$productId::$planTitle';

  int quantityFor(String productId, String planTitle) {
    final id = lineId(productId, planTitle);
    for (final item in state.items) {
      if (item['id'] == id) return (item['quantity'] as num).toInt();
    }
    return 0;
  }

  void addProduct({
    required ProductItem product,
    required ProductSupplyPlan plan,
    required int quantity,
  }) {
    final id = lineId(product.id, plan.title);
    final items = state.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final index = items.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      items[index]['quantity'] =
          ((items[index]['quantity'] as num).toInt() + quantity)
              .clamp(1, 10)
              .toInt();
    } else {
      items.add({
        'id': id,
        'productId': product.id,
        'title': product.name,
        'desc': plan.subtitle,
        'plan': plan.title,
        'price': plan.price,
        'quantity': quantity.clamp(1, 10).toInt(),
        'image': product.images.isEmpty ? '' : product.images.first,
      });
    }
    emit(CartState(items: List.unmodifiable(items)));
  }

  void setQuantity(String id, int quantity) {
    final items = state.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final index = items.indexWhere((item) => item['id'] == id);
    if (index < 0) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index]['quantity'] = quantity.clamp(1, 10).toInt();
    }
    emit(CartState(items: List.unmodifiable(items)));
  }

  void remove(String id) => emit(
    CartState(
      items: List.unmodifiable(
        state.items
            .where((item) => item['id'] != id)
            .map((item) => Map<String, dynamic>.from(item)),
      ),
    ),
  );

  void restore(Map<String, dynamic> item, int index) {
    if (state.items.any((entry) => entry['id'] == item['id'])) return;
    final items = state.items
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    items.insert(index.clamp(0, items.length).toInt(), Map<String, dynamic>.from(item));
    emit(CartState(items: List.unmodifiable(items)));
  }

  void replaceAll(List<Map<String, dynamic>> items) => emit(
    CartState(
      items: List.unmodifiable(
        items.map((item) => Map<String, dynamic>.from(item)),
      ),
    ),
  );

  void clear() => emit(const CartState());
}
