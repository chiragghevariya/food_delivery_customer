import '../utils/json_utils.dart';

class Category {
  final int id;
  final String name;
  final String? image;

  Category({required this.id, required this.name, this.image});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: toInt(json['id']),
        name: json['name'] ?? '',
        image: json['image'],
      );
}
