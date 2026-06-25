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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(height: 180, width: double.infinity, child: _banner()),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _openBadge(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        restaurant.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F3F5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Delivery: \$2.00',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold),
                        ),
                        if (restaurant.distanceKm != null) ...[
                          const SizedBox(width: 20),
                          const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final color = open ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        open ? 'OPEN' : 'CLOSED',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
