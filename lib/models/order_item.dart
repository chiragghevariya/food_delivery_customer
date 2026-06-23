import '../utils/json_utils.dart';

class OrderItem {
  final int id;
  final int? menuItemId;
  final String? name; // item name (sent by the API when the relation is loaded)
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    this.menuItemId,
    this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: toInt(json['id']),
        menuItemId: json['menu_item_id'] == null ? null : toInt(json['menu_item_id']),
        name: json['name'],
        quantity: toInt(json['quantity']),
        unitPrice: toDouble(json['unit_price']),
        subtotal: toDouble(json['subtotal']),
      );
}
