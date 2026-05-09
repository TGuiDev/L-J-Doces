import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalItemCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  double get totalPrice => totalAmount;

  bool addItem(Product product, {int quantity = 1, String observation = ''}) {
    if (quantity <= 0 || product.stockQuantity <= 0) {
      return false;
    }

    final currentQuantity = _items[product.id]?.quantity ?? 0;
    if (currentQuantity >= product.stockQuantity) {
      return false;
    }

    final nextQuantity = currentQuantity + quantity;
    final safeQuantity = nextQuantity > product.stockQuantity ? product.stockQuantity : nextQuantity;

    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          product: existingItem.product,
          quantity: safeQuantity,
          observation: observation.isNotEmpty ? observation : existingItem.observation,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: DateTime.now().toString(),
          product: product,
          quantity: safeQuantity,
          observation: observation,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          product: existingItem.product,
          quantity: existingItem.quantity - 1,
          observation: existingItem.observation,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
