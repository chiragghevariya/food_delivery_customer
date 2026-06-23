import '../utils/json_utils.dart';
import 'menu_item.dart';

class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final double? lat;
  final double? lng;
  final String? logo;
  final String? banner;
  final bool isOpen;
  final double rating;
  final double? distanceKm; // only present in the "nearby" response
  final List<MenuItem> menuItems; // only present in the "show one restaurant" response

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.lat,
    this.lng,
    this.logo,
    this.banner,
    required this.isOpen,
    required this.rating,
    this.distanceKm,
    this.menuItems = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: toInt(json['id']),
        name: json['name'] ?? '',
        description: json['description'],
        address: json['address'],
        lat: toDoubleOrNull(json['lat']),
        lng: toDoubleOrNull(json['lng']),
        logo: json['logo'],
        banner: json['banner'],
        isOpen: toBool(json['is_open']),
        rating: toDouble(json['rating']),
        distanceKm: toDoubleOrNull(json['distance_km']),
        menuItems: (json['menu_items'] as List?)
                ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
