import '../utils/json_utils.dart';
import 'category.dart';

class MenuItem {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final bool isAvailable;
  final Category? category;

  MenuItem({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.isAvailable,
    this.category,
  });

  /// Name of the category, or "Other" when the item has none.
  String get categoryName => category?.name ?? 'Other';

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: toInt(json['id']),
        restaurantId: toInt(json['restaurant_id']),
        categoryId: json['category_id'] == null ? null : toInt(json['category_id']),
        name: json['name'] ?? '',
        description: json['description'],
        price: toDouble(json['price']),
        image: json['image'],
        isAvailable: toBool(json['is_available']),
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );
}
