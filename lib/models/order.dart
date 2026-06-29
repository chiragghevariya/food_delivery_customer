import '../utils/json_utils.dart';
import 'order_item.dart';

/// Holds the rider information for live tracking.
class RiderInfo {
  final int id;
  final String name;
  final String? phone;
  final double? lat;
  final double? lng;
  final DateTime? locationUpdatedAt;

  RiderInfo({
    required this.id,
    required this.name,
    this.phone,
    this.lat,
    this.lng,
    this.locationUpdatedAt,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) => RiderInfo(
        id: toInt(json['id']),
        name: json['name'] ?? '',
        phone: json['phone'],
        lat: toDoubleOrNull(json['lat']),
        lng: toDoubleOrNull(json['lng']),
        locationUpdatedAt: toDate(json['location_updated_at']),
      );
}

/// One entry in the order's status timeline.
class OrderStatusEntry {
  final String status;
  final String? note;
  final DateTime? createdAt;

  OrderStatusEntry({required this.status, this.note, this.createdAt});

  factory OrderStatusEntry.fromJson(Map<String, dynamic> json) => OrderStatusEntry(
        status: json['status'] ?? '',
        note: json['note'],
        createdAt: toDate(json['created_at']),
      );
}

class Order {
  final int id;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? address;
  final double? lat;
  final double? lng;
  final String? notes;
  final int? restaurantId;
  final String? restaurantName;
  final RiderInfo? rider;
  final List<OrderItem> items;
  final List<OrderStatusEntry> statusHistory;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.address,
    this.lat,
    this.lng,
    this.notes,
    this.restaurantId,
    this.restaurantName,
    this.rider,
    this.items = const [],
    this.statusHistory = const [],
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isFinished => status == 'delivered' || status == 'cancelled';

  factory Order.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'];
    final riderJson = json['rider'];
    return Order(
      id: toInt(json['id']),
      status: json['status'] ?? 'pending',
      subtotal: toDouble(json['subtotal']),
      deliveryFee: toDouble(json['delivery_fee']),
      total: toDouble(json['total']),
      address: json['address'],
      lat: toDoubleOrNull(json['lat']),
      lng: toDoubleOrNull(json['lng']),
      notes: json['notes'],
      restaurantId: restaurant is Map ? toInt(restaurant['id']) : null,
      restaurantName: restaurant is Map ? restaurant['name'] as String? : null,
      rider: riderJson is Map ? RiderInfo.fromJson(riderJson as Map<String, dynamic>) : null,
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      statusHistory: (json['status_history'] as List?)
              ?.map((e) => OrderStatusEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: toDate(json['created_at']),
    );
  }
}
