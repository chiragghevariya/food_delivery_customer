import 'package:dio/dio.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'api_service.dart';

/// Talks to the /orders endpoints (all require the user to be logged in).
class OrderService {
  final Dio _dio = ApiService.instance.dio;

  /// POST /api/orders
  Future<Order> placeOrder({
    required int restaurantId,
    required List<CartItem> items,
    required String address,
    double? lat,
    double? lng,
    String? notes,
    String? paymentIntentId,
  }) async {
    final res = await _dio.post('/orders', data: {
      'restaurant_id': restaurantId,
      // the API only needs the item id + quantity; it works out the prices itself
      'items': items
          .map((c) => {'menu_item_id': c.menuItem.id, 'quantity': c.quantity})
          .toList(),
      'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
    });
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/orders/payment-intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required int restaurantId,
    required List<CartItem> items,
  }) async {
    final res = await _dio.post('/orders/payment-intent', data: {
      'restaurant_id': restaurantId,
      'items': items
          .map((c) => {'menu_item_id': c.menuItem.id, 'quantity': c.quantity})
          .toList(),
    });
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/orders  (the logged-in customer's own orders)
  Future<List<Order>> myOrders() async {
    final res = await _dio.get('/orders');
    final list = res.data['data'] as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/orders/{id}
  Future<Order> getOrder(int id) async {
    final res = await _dio.get('/orders/$id');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/orders/{id}/cancel
  Future<Order> cancelOrder(int id) async {
    final res = await _dio.post('/orders/$id/cancel');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
