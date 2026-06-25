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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    final order = _order!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Status Header Card
            _buildStatusHeaderCard(order),
            const SizedBox(height: 16),

            // Live Map Card
            if (order.lat != null && order.lng != null) ...[
              _map(order),
              const SizedBox(height: 16),
            ],

            // Delivery Details Card
            _buildDeliveryDetailsCard(order),
            const SizedBox(height: 16),

            // Order Items & Bill Receipt Card
            _buildItemsAndReceiptCard(order),
            const SizedBox(height: 16),

            // Timeline Card
            _buildTimelineCard(order),
            const SizedBox(height: 24),

            // Cancel Button
            if (order.isPending) ...[
              _buildCancelButton(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'accepted':
        return Icons.assignment_turned_in_rounded;
      case 'preparing':
        return Icons.soup_kitchen_rounded;
      case 'ready_for_pickup':
        return Icons.shopping_bag_rounded;
      case 'picked_up':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for restaurant confirmation...';
      case 'accepted':
        return 'The restaurant has accepted your order.';
      case 'preparing':
        return 'The kitchen is preparing your delicious meal!';
      case 'ready_for_pickup':
        return 'Your food is ready for pickup or courier dispatch.';
      case 'picked_up':
        return 'Our courier is on the way to you!';
      case 'delivered':
        return 'Order delivered. Enjoy your hot meal!';
      case 'cancelled':
        return 'This order has been cancelled.';
      default:
        return 'We are updating your order status...';
    }
  }

  Widget _buildStatusHeaderCard(Order order) {
    final statusColor = OrderStatusUi.color(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final statusMsg = _getStatusMessage(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.restaurantName ?? 'Restaurant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusMsg,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.createdAt != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F3F5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ordered on',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(order.createdAt!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _map(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard(Order order) {
    if ((order.address == null || order.address!.isEmpty) && (order.notes == null || order.notes!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          if (order.address != null && order.address!.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.address!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            if (order.address != null && order.address!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F3F5)),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.blueGrey,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Note for courier',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsAndReceiptCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
            child: Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Items List
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${it.quantity}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it.name ?? 'Item #${it.menuItemId ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '\$${it.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),
          // Bill Receipt Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildReceiptRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildReceiptRow('Delivery fee', '\$${order.deliveryFee.toStringAsFixed(2)}'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: _buildReceiptRow('Total Price', '\$${order.total.toStringAsFixed(2)}', bold: true),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      color: bold ? AppColors.primary : AppColors.text,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold ? style : const TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: style,
        ),
      ],
    );
  }

  Widget _buildTimelineCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F3F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Updates',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          _timeline(order),
        ],
      ),
    );
  }

  Widget _timeline(Order order) {
    if (order.statusHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'No history yet.',
          style: TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
      );
    }
    return Column(
      children: order.statusHistory.asMap().entries.map((e) {
        final index = e.key;
        final isLast = index == order.statusHistory.length - 1;
        final entry = e.value;
        final color = OrderStatusUi.color(entry.status);
        final icon = _getStatusIcon(entry.status);
        final isCurrent = index == order.statusHistory.length - 1; // latest status in history is the current one

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // dot + connecting line
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent ? color : color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? color : color.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: isCurrent ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ] : null,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isCurrent ? Colors.white : color,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // label + note + time
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        OrderStatusUi.label(entry.status),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: isCurrent ? AppColors.text : AppColors.textLight,
                        ),
                      ),
                      if (entry.note != null && entry.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.note!,
                          style: TextStyle(
                            color: isCurrent ? AppColors.text.withOpacity(0.7) : AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (entry.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(entry.createdAt!),
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary.withOpacity(0.8) : AppColors.textLight.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildCancelButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: _cancelOrder,
        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
        label: const Text(
          'Cancel Order',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}
