import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
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
        _address.text = 'Fetching address...';
      });

      final address = await LocationService.getAddressFromLatLng(loc.lat, loc.lng);

      if (mounted) {
        setState(() {
          _address.text = address;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Current location added')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_lat != null && _lng != null) {
            _address.text = '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}';
          } else {
            _address.clear();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    if (cart.isEmpty || cart.restaurantId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    setState(() => _placing = true);
    try {
      String? paymentIntentId;

      if (!kIsWeb) {
        debugPrint('=== Stripe Checkout: Starting PaymentIntent creation on backend ===');
        // 1) Create Stripe Payment Intent on Backend
        final intentData = await _orderService.createPaymentIntent(
          restaurantId: cart.restaurantId!,
          items: cart.items,
        );

        final clientSecret = intentData['client_secret'] as String;
        paymentIntentId = intentData['payment_intent_id'] as String;
        debugPrint('=== Stripe Checkout: PaymentIntent created successfully. ID: $paymentIntentId ===');

        // 2) Initialize Stripe Payment Sheet
        debugPrint('=== Stripe Checkout: Initializing Stripe Payment Sheet ===');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'FoodDash Delivery',
            style: ThemeMode.light,
            returnURL: 'fooddeliverycustomer://redirect',
            billingDetails: BillingDetails(
              name: user?.name,
              email: user?.email,
              phone: user?.phone,
            ),
            billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
              name: CollectionMode.always,
              email: CollectionMode.always,
              phone: CollectionMode.always,
              address: AddressCollectionMode.full,
            ),
          ),
        );
        debugPrint('=== Stripe Checkout: Stripe Payment Sheet Initialized ===');

        // 3) Present Stripe Payment Sheet on Phone
        debugPrint('=== Stripe Checkout: Presenting Stripe Payment Sheet ===');
        await Stripe.instance.presentPaymentSheet();
        debugPrint('=== Stripe Checkout: Payment Sheet presented and completed successfully ===');
      }

      debugPrint('=== Stripe Checkout: Submitting order details to backend ===');
      // 4) Complete order placing on backend with verified payment_intent_id (mobile only) or null (web)
      final order = await _orderService.placeOrder(
        restaurantId: cart.restaurantId!,
        items: cart.items,
        address: _address.text.trim(),
        lat: _lat,
        lng: _lng,
        notes: _notes.text.trim(),
        paymentIntentId: paymentIntentId,
      );
      debugPrint('=== Stripe Checkout: Order placed successfully on backend. Order ID: ${order.id} ===');

      cart.clear();
      if (!mounted) return;
      // Replace the cart screen with the new order's detail screen.
      Navigator.pushReplacementNamed(context, Routes.orderDetail, arguments: order.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
    } on StripeException catch (e) {
      if (!mounted) return;
      debugPrint('StripeException: ${e.error.localizedMessage} | Code: ${e.error.code} | Message: ${e.error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.error.localizedMessage ?? e.error.message ?? 'Payment cancelled or failed.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('Order placement failed error: $e');
      debugPrint(stack.toString());
      
      String displayError = e.toString();
      if (e is DioException) {
        final res = e.response;
        if (res != null) {
          displayError = 'Server Error (${res.statusCode}): ${res.data}';
        } else {
          displayError = 'Network Error: ${e.message}';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('Items in Cart'),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F3F5)),
                    ),
                    child: Column(
                      children: cart.items.map((item) => _cartLine(cart, item.menuItem.id, item.menuItem.name,
                          item.menuItem.price, item.quantity, item.subtotal)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Payment Summary'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F3F5)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Subtotal', cart.subtotal),
                        const SizedBox(height: 6),
                        _summaryRow('Delivery fee', CartProvider.deliveryFee),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        _summaryRow('Total', cart.total, bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Delivery Details'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F3F5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _address,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Enter a delivery address' : null,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _useMyLocation,
                            icon: const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                            label: Text(
                              _lat == null ? 'Use my current GPS location' : 'Location added ✓',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notes,
                          decoration: const InputDecoration(
                            labelText: 'Add notes for the rider...',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 0.5),
      ),
    );
  }

  Widget _cartLine(
      CartProvider cart, int id, String name, double price, int qty, double subtotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${price.toStringAsFixed(2)} each',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          // quantity stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => cart.decrease(id),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textLight, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$qty',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                ),
              ),
              IconButton(
                onPressed: () => cart.increase(id),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              '\$${subtotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      color: bold ? AppColors.primary : AppColors.text,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold ? style : const TextStyle(color: AppColors.textLight, fontSize: 14)),
        Text('\$${value.toStringAsFixed(2)}', style: style)
      ],
    );
  }
}
