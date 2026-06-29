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
import '../widgets/shimmer_loading.dart';

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'DELIVERING TO',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              'Bhavnagar, Gujarat, India',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My orders',
            onPressed: () => Navigator.pushNamed(context, Routes.orders),
          ),
          // Cart icon with a live item-count badge.
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Cart',
                  onPressed: () => Navigator.pushNamed(context, Routes.cart),
                ),
                if (cart.totalQuantity > 0)
                  Positioned(right: 6, top: 6, child: _badge(cart.totalQuantity)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, prov, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar with clean shadow
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants, dishes...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              // Category chips
              if (prov.categories.isNotEmpty)
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: prov.categories
                        .map((cat) => CategoryChip(
                              label: cat.name,
                              imageUrl: cat.image,
                              selected: prov.selectedCategoryId == cat.id,
                              onTap: () => prov.selectCategory(cat.id),
                            ))
                        .toList(),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Popular Restaurants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              Expanded(child: _buildList(prov)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(RestaurantProvider prov) {
    if (prov.loading && prov.restaurants.isEmpty) {
      return const ShimmerListPlaceholder(count: 3);
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
