import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../utils/error_utils.dart';
import '../widgets/status_badge.dart';

/// Lists the logged-in customer's orders.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _service = OrderService();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.myOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.myOrders());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(apiErrorMessage(snapshot.error!)));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('You have no orders yet.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, i) => _orderCard(orders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            StatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.restaurantName ?? 'Restaurant'),
            const SizedBox(height: 2),
            Text(
              '\$${order.total.toStringAsFixed(2)}'
              '${order.createdAt != null ? '  •  ${DateFormat('MMM d, h:mm a').format(order.createdAt!)}' : ''}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, Routes.orderDetail, arguments: order.id),
      ),
    );
  }
}
