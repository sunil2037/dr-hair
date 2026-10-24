import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/app_local_cache.dart';
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
  static const _storageKey = 'shop_cart_v1';

  CartCubit({AppLocalCache? cache})
      : _cache = cache ?? AppLocalCache.instance,
        super(const CartState()) {
    _restore();
  }

  final AppLocalCache _cache;

  void _restore() {
    final raw = _cache.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .where(
            (item) =>
                item['id'] is String &&
                item['price'] is num &&
                item['quantity'] is num &&
                (item['quantity'] as num) > 0,
          )
          .map((item) {
            final safeItem = Map<String, dynamic>.from(item);
            safeItem['price'] = (item['price'] as num).toInt().clamp(0, 10000000);
            safeItem['quantity'] =
                (item['quantity'] as num).toInt().clamp(1, 10);
            return safeItem;
          })
          .toList(growable: false);
      emit(CartState(items: List.unmodifiable(items)));
    } catch (_) {
      _cache.remove(_storageKey);
    }
  }

  void _persist(List<Map<String, dynamic>> items) {
    _cache.put(_storageKey, jsonEncode(items));
  }

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
    _persist(items);
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
    _persist(items);
  }

  void remove(String id) {
    final items = state.items
        .where((item) => item['id'] != id)
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    emit(CartState(items: List.unmodifiable(items)));
    _persist(items);
  }

  void restore(Map<String, dynamic> item, int index) {
    if (state.items.any((entry) => entry['id'] == item['id'])) return;
    final items = state.items
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    items.insert(index.clamp(0, items.length).toInt(), Map<String, dynamic>.from(item));
    emit(CartState(items: List.unmodifiable(items)));
    _persist(items);
  }

  void replaceAll(List<Map<String, dynamic>> items) {
    final copy = items.map((item) => Map<String, dynamic>.from(item)).toList();
    emit(CartState(items: List.unmodifiable(copy)));
    _persist(copy);
  }

  void clear() {
    emit(const CartState());
    _persist(const []);
  }
}
