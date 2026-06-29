import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer container for custom skeletons.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A loading skeleton for restaurant/menu list cards.
class ShimmerListPlaceholder extends StatelessWidget {
  final int count;

  const ShimmerListPlaceholder({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F3F5)),
            ),
            child: Row(
              children: [
                // Image placeholder
                const ShimmerBox(width: 80, height: 80, borderRadius: 12),
                const SizedBox(width: 16),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(width: 150, height: 16),
                      const SizedBox(height: 8),
                      const ShimmerBox(width: 100, height: 12),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ShimmerBox(width: 60, height: 12),
                          const ShimmerBox(width: 40, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A loading skeleton for detail/info screens.
class ShimmerDetailPlaceholder extends StatelessWidget {
  const ShimmerDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Placeholder
          const ShimmerBox(width: double.infinity, height: 200, borderRadius: 20),
          const SizedBox(height: 24),
          // Title
          const ShimmerBox(width: 220, height: 24),
          const SizedBox(height: 12),
          // Subtitle
          const ShimmerBox(width: 140, height: 16),
          const SizedBox(height: 24),
          // Section header
          const ShimmerBox(width: 100, height: 18),
          const SizedBox(height: 16),
          // List of items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const ShimmerBox(width: 40, height: 40, borderRadius: 8),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShimmerBox(width: 120, height: 14),
                            const SizedBox(height: 6),
                            const ShimmerBox(width: 80, height: 10),
                          ],
                        ),
                      ],
                    ),
                    const ShimmerBox(width: 40, height: 14),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
