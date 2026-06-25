import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// A selectable category filter chip with circular image.
class CategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFEDEFF3),
                  width: selected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected ? AppColors.primary.withOpacity(0.12) : Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: _image(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (imageUrl == null || !imageUrl!.startsWith('http')) {
      return const Center(
        child: Icon(Icons.fastfood, color: AppColors.primary, size: 24),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.fastfood, color: AppColors.primary, size: 24),
      ),
    );
  }
}
