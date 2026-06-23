import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/restaurant.dart';

/// A card showing one restaurant in the home list.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 140, width: double.infinity, child: _banner()),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _openBadge(),
                    ],
                  ),
                  if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(restaurant.rating.toStringAsFixed(1)),
                      if (restaurant.distanceKm != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text('${restaurant.distanceKm!.toStringAsFixed(1)} km'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    final url = restaurant.banner ?? restaurant.logo;
    // Only try to load real http(s) image URLs; otherwise show a placeholder.
    if (url == null || !url.startsWith('http')) {
      return Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.restaurant, size: 48, color: AppColors.textLight),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFFEDEDED)),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.restaurant, size: 48, color: AppColors.textLight),
      ),
    );
  }

  Widget _openBadge() {
    final open = restaurant.isOpen;
    final color = open ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        open ? 'Open' : 'Closed',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
