import 'menu_item.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;
  final Map<String, dynamic> customizations;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.specialInstructions,
    this.customizations = const {},
  });

  double get totalPrice => menuItem.effectivePrice * quantity;

  CartItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
    Map<String, dynamic>? customizations,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      customizations: customizations ?? this.customizations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'customizations': customizations,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'],
      specialInstructions: json['specialInstructions'],
      customizations: Map<String, dynamic>.from(json['customizations'] ?? {}),
    );
  }
}
