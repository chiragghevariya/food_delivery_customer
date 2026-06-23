import 'menu_item.dart';

/// One line in the shopping cart: a menu item + how many of it.
class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get subtotal => menuItem.price * quantity;
}
