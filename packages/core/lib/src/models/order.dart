import 'enums.dart';
import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double tip;
  final double total;
  final OrderStatus status;
  final String deliveryAddress;
  final DateTime estimatedDeliveryTime;
  final String? deliveryPersonId;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    this.tip = 0.0,
    required this.total,
    this.status = OrderStatus.placed,
    required this.deliveryAddress,
    required this.estimatedDeliveryTime,
    this.deliveryPersonId,
    required this.paymentMethod,
    this.isPaid = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Order copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? tip,
    double? total,
    OrderStatus? status,
    String? deliveryAddress,
    DateTime? estimatedDeliveryTime,
    String? deliveryPersonId,
    PaymentMethod? paymentMethod,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'tip': tip,
      'total': total,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'estimatedDeliveryTime': estimatedDeliveryTime.toIso8601String(),
      'deliveryPersonId': deliveryPersonId,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'isPaid': isPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      restaurantId: json['restaurantId'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'],
      tax: json['tax'],
      deliveryFee: json['deliveryFee'],
      tip: json['tip'] ?? 0.0,
      total: json['total'],
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.placed,
      ),
      deliveryAddress: json['deliveryAddress'],
      estimatedDeliveryTime: DateTime.parse(json['estimatedDeliveryTime']),
      deliveryPersonId: json['deliveryPersonId'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentMethod'],
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      isPaid: json['isPaid'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
