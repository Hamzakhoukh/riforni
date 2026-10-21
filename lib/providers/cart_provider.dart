import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/supplier.dart';

class CartItem {
  final Product product;
  double quantity;
  Supplier? selectedSupplier;

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedSupplier,
  });
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;
  List<CartItem> get cartItems => _items.values.toList();
  int get totalItemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  double getQuantity(int productId) {
    return _items[productId]?.quantity ?? 0;
  }

  Supplier? getSelectedSupplier(int productId) {
    return _items[productId]?.selectedSupplier;
  }

  void setSelectedSupplier(int productId, Supplier? supplier) {
    if (_items.containsKey(productId)) {
      _items[productId]!.selectedSupplier = supplier;
      notifyListeners();
    }
  }

  void increment(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      _items[product.id!] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void decrement(Product product) {
    if (!_items.containsKey(product.id)) return;
    final current = _items[product.id]!.quantity;
    if (current <= 1) {
      _items.remove(product.id);
    } else {
      _items[product.id]!.quantity -= 1;
    }
    notifyListeners();
  }

  void setQuantity(Product product, double quantity) {
    if (quantity <= 0) {
      _items.remove(product.id);
    } else {
      if (_items.containsKey(product.id)) {
        _items[product.id]!.quantity = quantity;
      } else {
        _items[product.id!] = CartItem(product: product, quantity: quantity);
      }
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
