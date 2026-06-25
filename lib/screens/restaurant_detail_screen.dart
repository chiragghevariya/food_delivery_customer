import 'package:cached_network_image/cached_network_image.dart';
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
      bottomNavigationBar: _cartBar(),
      body: FutureBuilder<Restaurant>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text(apiErrorMessage(snapshot.error!))),
            );
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

    return CustomScrollView(
      slivers: [
        _sliverBanner(restaurant),
        SliverToBoxAdapter(child: _headerCard(restaurant)),
        if (restaurant.menuItems.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'This restaurant has no menu items yet.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            ),
          ),
        // One section per category.
        for (final entry in groups.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = entry.value[index];
                return MenuItemTile(
                  item: item,
                  onAdd: () {
                    context.read<CartProvider>().addItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _sliverBanner(Restaurant restaurant) {
    final url = restaurant.banner ?? restaurant.logo;
    final hasImage = url != null && url.startsWith('http');

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.4),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: const Color(0xFFEDEDED),
                child: const Icon(Icons.restaurant, size: 64, color: AppColors.textLight),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
            Text(
              restaurant.description!,
              style: const TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: restaurant.isOpen ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      restaurant.isOpen ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: restaurant.isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.isOpen ? 'Open Now' : 'Closed',
                      style: TextStyle(
                        color: restaurant.isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.delivery_dining_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Delivery: \$2.00',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
            ],
          ),
          if (restaurant.address != null && restaurant.address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F3F5)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    restaurant.address!,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${cart.totalQuantity} item(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('View Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
