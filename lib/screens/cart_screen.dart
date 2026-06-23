import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../providers/cart_provider.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../utils/error_utils.dart';
import '../widgets/primary_button.dart';

/// Shows the cart, lets the user edit quantities and place the order.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final OrderService _orderService = OrderService();

  bool _placing = false;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      setState(() {
        _lat = loc.lat;
        _lng = loc.lng;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Current location added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    if (cart.isEmpty || cart.restaurantId == null) return;

    setState(() => _placing = true);
    try {
      final order = await _orderService.placeOrder(
        restaurantId: cart.restaurantId!,
        items: cart.items,
        address: _address.text.trim(),
        lat: _lat,
        lng: _lng,
        notes: _notes.text.trim(),
      );
      cart.clear();
      if (!mounted) return;
      // Replace the cart screen with the new order's detail screen.
      Navigator.pushReplacementNamed(context, Routes.orderDetail, arguments: order.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order placed!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- cart items ---
                  ...cart.items.map((item) => _cartLine(cart, item.menuItem.id, item.menuItem.name,
                      item.menuItem.price, item.quantity, item.subtotal)),
                  const Divider(height: 24),
                  // --- price summary ---
                  _summaryRow('Subtotal', cart.subtotal),
                  _summaryRow('Delivery fee', CartProvider.deliveryFee),
                  const SizedBox(height: 4),
                  _summaryRow('Total', cart.total, bold: true),
                  const SizedBox(height: 20),
                  // --- delivery details ---
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a delivery address' : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _useMyLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(_lat == null ? 'Use my current location' : 'Location added ✓'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Place Order  •  \$${cart.total.toStringAsFixed(2)}',
                    loading: _placing,
                    onPressed: () => _placeOrder(cart),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cartLine(
      CartProvider cart, int id, String name, double price, int qty, double subtotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          // quantity stepper
          IconButton(
            onPressed: () => cart.decrease(id),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => cart.increase(id),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          ),
          SizedBox(
            width: 60,
            child: Text('\$${subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 15,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? AppColors.primary : AppColors.text,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text('\$${value.toStringAsFixed(2)}', style: style)],
      ),
    );
  }
}
