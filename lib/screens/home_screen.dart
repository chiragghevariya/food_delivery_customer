import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/restaurant_card.dart';

/// Lists restaurants with a search bar and category filter chips.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load data after the first frame (so the provider is available).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Wait 400ms after the user stops typing before searching (avoids spamming the API).
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<RestaurantProvider>().setSearch(value);
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My orders',
            onPressed: () => Navigator.pushNamed(context, Routes.orders),
          ),
          // Cart icon with a live item-count badge.
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Cart',
                  onPressed: () => Navigator.pushNamed(context, Routes.cart),
                ),
                if (cart.totalQuantity > 0)
                  Positioned(right: 6, top: 6, child: _badge(cart.totalQuantity)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, prov, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              // Category chips
              if (prov.categories.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: prov.categories
                        .map((cat) => CategoryChip(
                              label: cat.name,
                              selected: prov.selectedCategoryId == cat.id,
                              onTap: () => prov.selectCategory(cat.id),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildList(prov)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(RestaurantProvider prov) {
    if (prov.loading && prov.restaurants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.error != null && prov.restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(prov.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: prov.loadRestaurants,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (prov.restaurants.isEmpty) {
      return const Center(child: Text('No restaurants found.'));
    }
    return RefreshIndicator(
      onRefresh: prov.loadRestaurants,
      child: ListView.builder(
        itemCount: prov.restaurants.length,
        itemBuilder: (context, i) {
          final r = prov.restaurants[i];
          return RestaurantCard(
            restaurant: r,
            onTap: () =>
                Navigator.pushNamed(context, Routes.restaurantDetail, arguments: r.id),
          );
        },
      ),
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
