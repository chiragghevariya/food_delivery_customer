import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

/// Holds the shopping cart in memory and notifies the UI when it changes.
class CartProvider extends ChangeNotifier {
  /// Flat delivery fee — must match the backend (OrderService::DELIVERY_FEE = $2).
  static const double deliveryFee = 2.0;

  final Map<int, CartItem> _items = {}; // key = menu item id
  int? _restaurantId;

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int? get restaurantId => _restaurantId;

  int get totalQuantity => _items.values.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);
  double get total => isEmpty ? 0 : subtotal + deliveryFee;

  void addItem(MenuItem item) {
    // The cart holds items from ONE restaurant only. Adding from a different
    // restaurant clears the old cart first.
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      _items.clear();
    }
    _restaurantId = item.restaurantId;

    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartItem(menuItem: item);
    }
    notifyListeners();
  }

  void increase(int menuItemId) {
    final item = _items[menuItemId];
    if (item != null) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrease(int menuItemId) {
    final item = _items[menuItemId];
    if (item == null) return;
    item.quantity--;
    if (item.quantity <= 0) _items.remove(menuItemId);
    if (_items.isEmpty) _restaurantId = null;
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    _items.remove(menuItemId);
    if (_items.isEmpty) _restaurantId = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurantId = null;
    notifyListeners();
  }
}
