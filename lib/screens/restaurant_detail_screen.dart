import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import '../services/restaurant_service.dart';
import '../utils/error_utils.dart';
import '../widgets/menu_item_tile.dart';

/// Shows one restaurant and its menu, grouped by category.
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final RestaurantService _service = RestaurantService();
  Future<Restaurant>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the restaurant id passed via the named route, then load it once.
    if (_future == null) {
      final id = ModalRoute.of(context)!.settings.arguments as int;
      _future = _service.getRestaurant(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      bottomNavigationBar: _cartBar(),
      body: FutureBuilder<Restaurant>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(apiErrorMessage(snapshot.error!)));
          }
          final restaurant = snapshot.data!;
          return _buildContent(restaurant);
        },
      ),
    );
  }

  Widget _buildContent(Restaurant restaurant) {
    // Group the menu items by their category name.
    final groups = <String, List<MenuItem>>{};
    for (final item in restaurant.menuItems) {
      groups.putIfAbsent(item.categoryName, () => []).add(item);
    }

    return ListView(
      children: [
        _header(restaurant),
        if (restaurant.menuItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('This restaurant has no menu items yet.')),
          ),
        // One section per category.
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final item in entry.value)
            MenuItemTile(
              item: item,
              onAdd: () {
                context.read<CartProvider>().addItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} added to cart'), duration: const Duration(seconds: 1)),
                );
              },
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _header(Restaurant restaurant) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(restaurant.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(restaurant.description!, style: const TextStyle(color: AppColors.textLight)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(restaurant.rating.toStringAsFixed(1)),
              const SizedBox(width: 12),
              Icon(
                restaurant.isOpen ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: restaurant.isOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(restaurant.isOpen ? 'Open' : 'Closed'),
            ],
          ),
          if (restaurant.address != null && restaurant.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(child: Text(restaurant.address!, style: const TextStyle(color: AppColors.textLight))),
              ],
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }

  /// A bar at the bottom that appears when the cart has items.
  Widget _cartBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.cart),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${cart.totalQuantity} item(s)'),
                  const Text('View cart'),
                  Text('\$${cart.subtotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
