import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/order.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../utils/error_utils.dart';
import '../utils/status_utils.dart';
import '../widgets/status_badge.dart';

/// Shows one order with its items and a LIVE status timeline.
/// While the order is in progress, it re-checks the status every few seconds.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _service = OrderService();

  int? _orderId;
  Order? _order;
  bool _loading = true;
  String? _error;
  String? _lastStatus; // used to detect status changes for notifications
  Timer? _poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == null) {
      _orderId = ModalRoute.of(context)!.settings.arguments as int;
      _load();
      // Re-check the order every 10 seconds (the "live" part).
      _poll = Timer.periodic(const Duration(seconds: 10), (_) {
        if (_order == null || !_order!.isFinished) _load();
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await _service.getOrder(_orderId!);
      // If the status changed since last time, show a local notification.
      if (_lastStatus != null && _lastStatus != order.status) {
        NotificationService.show(
          'Order update',
          'Your order is now: ${OrderStatusUi.label(order.status)}',
        );
      }
      _lastStatus = order.status;
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
      });
      // Stop polling once the order is finished.
      if (order.isFinished) _poll?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    try {
      final order = await _service.cancelOrder(_orderId!);
      if (!mounted) return;
      setState(() => _order = order);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order cancelled')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_orderId ?? ''}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final order = _order!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // current status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),

          // delivery map (needs a Google Maps API key — see README)
          if (order.lat != null && order.lng != null) _map(order),

          // items
          _sectionTitle('Items'),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${it.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(it.name ?? 'Item #${it.menuItemId ?? ''}')),
                    Text('\$${it.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
              )),
          const Divider(height: 24),

          // totals
          _row('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
          _row('Delivery fee', '\$${order.deliveryFee.toStringAsFixed(2)}'),
          _row('Total', '\$${order.total.toStringAsFixed(2)}', bold: true),

          if (order.address != null && order.address!.isNotEmpty) ...[
            _sectionTitle('Delivery address'),
            Text(order.address!),
          ],

          // live status timeline
          _sectionTitle('Status timeline'),
          _timeline(order),

          const SizedBox(height: 16),

          // cancel button (only when still pending)
          if (order.isPending)
            OutlinedButton.icon(
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text('Cancel order', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _map(Order order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(order.lat!, order.lng!),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('delivery'),
                position: LatLng(order.lat!, order.lng!),
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            liteModeEnabled: true, // a lightweight, mostly-static map (Android)
          ),
        ),
      ),
    );
  }

  /// Vertical timeline built from the order's status_history.
  Widget _timeline(Order order) {
    if (order.statusHistory.isEmpty) {
      return const Padding(padding: EdgeInsets.only(top: 8), child: Text('No history yet.'));
    }
    return Column(
      children: order.statusHistory.asMap().entries.map((e) {
        final isLast = e.key == order.statusHistory.length - 1;
        final entry = e.value;
        final color = OrderStatusUi.color(entry.status);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // dot + connecting line
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(width: 12),
              // label + note + time
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(OrderStatusUi.label(entry.status),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (entry.note != null && entry.note!.isNotEmpty)
                        Text(entry.note!, style: const TextStyle(color: AppColors.textLight)),
                      if (entry.createdAt != null)
                        Text(
                          DateFormat('MMM d, h:mm a').format(entry.createdAt!),
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 15,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? AppColors.primary : AppColors.text,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
