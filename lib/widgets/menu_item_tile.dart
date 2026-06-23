import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/menu_item.dart';

/// A row showing one menu item with an "add to cart" button.
class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;

  const MenuItemTile({super.key, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 56, height: 56, child: _image()),
      ),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '\$${item.price.toStringAsFixed(2)}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 30),
        onPressed: onAdd,
      ),
    );
  }

  Widget _image() {
    final url = item.image;
    if (url == null || !url.startsWith('http')) {
      return Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.fastfood, color: AppColors.textLight),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFFEDEDED),
        child: const Icon(Icons.fastfood, color: AppColors.textLight),
      ),
    );
  }
}
