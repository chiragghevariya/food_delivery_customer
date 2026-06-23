// Basic unit tests for the cart logic (pure Dart — no UI needed).
// This file also takes the place of Flutter's default counter test.

import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_customer/models/menu_item.dart';
import 'package:food_delivery_customer/providers/cart_provider.dart';

MenuItem _item(int id, double price, {int restaurantId = 1}) => MenuItem(
      id: id,
      restaurantId: restaurantId,
      name: 'Item $id',
      price: price,
      isAvailable: true,
    );

void main() {
  test('cart adds items and computes totals', () {
    final cart = CartProvider();
    cart.addItem(_item(1, 10.0));
    cart.addItem(_item(1, 10.0)); // same item -> quantity becomes 2
    cart.addItem(_item(2, 5.5));

    expect(cart.totalQuantity, 3);
    expect(cart.subtotal, 25.5);
    expect(cart.total, 25.5 + CartProvider.deliveryFee);
  });

  test('decreasing to zero removes the item', () {
    final cart = CartProvider();
    cart.addItem(_item(1, 10.0));
    cart.decrease(1);
    expect(cart.isEmpty, true);
  });

  test('adding from a different restaurant clears the old cart', () {
    final cart = CartProvider();
    cart.addItem(_item(1, 10.0, restaurantId: 1));
    cart.addItem(_item(9, 4.0, restaurantId: 2)); // different restaurant

    expect(cart.restaurantId, 2);
    expect(cart.totalQuantity, 1); // old cart was cleared
  });
}
