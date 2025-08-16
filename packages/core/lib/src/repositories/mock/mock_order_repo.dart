import 'dart:async';
import 'package:core/src/models/menu_item.dart';
import 'package:core/src/models/order.dart';
import 'package:core/src/models/cart_item.dart';
import 'package:core/src/models/enums.dart';
import 'package:core/src/repositories/order_repo.dart';

class MockOrderRepo implements OrderRepo {
  final List<Order> _orders = [
    Order(
      id: 'order_1',
      userId: '1',
      restaurantId: 'rest_1',
      items: [
        CartItem(
          id: 'item_1',
          quantity: 2,
          specialInstructions: 'No onions',
          menuItem: MenuItem(
            id: 'menu_4',
            name: 'Chocolate Milkshake',
            description: 'Sample description',
            price: 4.99,
            imageUrls: 'Creamy chocolate shake with whipped cream',
            restaurantId: 'rest_1',
            createdAt: DateTime.now().subtract(const Duration(days: 45)),
            updatedAt: DateTime.now().subtract(const Duration(days: 45)),
          ),
        ),
      ],
      subtotal: 17.98,
      tax: 1.80,
      deliveryFee: 2.99,
      total: 22.77,
      status: OrderStatus.placed,
      deliveryPersonId: '3',
      deliveryAddress: '123 Main St',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 45)),
      paymentMethod: PaymentMethod.upi,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    Order(
      id: 'order_2',
      userId: '1',
      restaurantId: 'rest_2',
      items: [
        CartItem(
          id: 'item_2',
          quantity: 1,
          specialInstructions: 'Extra cheese',
          menuItem: MenuItem(
            id: 'menu_3',
            name: 'French Fries',
            description: 'Crispy golden fries with sea salt',
            price: 3.99,
            imageUrls: 'https://example.com/sample.jpg',
            restaurantId: 'rest_1',
            createdAt: DateTime.now().subtract(const Duration(days: 45)),
            updatedAt: DateTime.now().subtract(const Duration(days: 45)),
          ),
        ),
      ],
      subtotal: 12.99,
      tax: 1.30,
      deliveryFee: 2.99,
      total: 17.28,
      status: OrderStatus.preparing,
      deliveryAddress: '123 Main St',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      paymentMethod: PaymentMethod.creditCard,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      deliveryPersonId: '3',
    ),
  ];

  final Map<String, StreamController<Order>> _orderControllers = {};

  @override
  Future<List<Order>> getOrdersByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _orders.where((order) => order.userId == userId).toList();
  }

  @override
  Future<List<Order>> getOrdersByRestaurant(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _orders
        .where((order) => order.restaurantId == restaurantId)
        .toList();
  }

  @override
  Future<List<Order>> getOrdersByDeliveryPerson(String deliveryPersonId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _orders
        .where((order) => order.deliveryPersonId == deliveryPersonId)
        .toList();
  }

  @override
  Future<Order> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _orders.firstWhere(
      (order) => order.id == id,
      orElse: () => throw Exception('Order not found'),
    );
  }

  @override
  Future<Order> createOrder(Order order) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final newOrder = order.copyWith(
      id: 'order_${_orders.length + 1}',
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _orders.add(newOrder);

    // Create a stream controller for this order if needed
    _orderControllers[newOrder.id] ??= StreamController<Order>.broadcast();
    _orderControllers[newOrder.id]!.add(newOrder);

    return newOrder;
  }

  @override
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = _orders[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updatedOrder;

    // Notify listeners if there's a stream for this order
    if (_orderControllers.containsKey(orderId)) {
      _orderControllers[orderId]!.add(updatedOrder);
    }

    return updatedOrder;
  }

  @override
  Future<Order> assignDeliveryPerson(
    String orderId,
    String deliveryPersonId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = _orders[index].copyWith(
      deliveryPersonId: deliveryPersonId,
      status: OrderStatus.inTransit,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updatedOrder;

    // Notify listeners if there's a stream for this order
    if (_orderControllers.containsKey(orderId)) {
      _orderControllers[orderId]!.add(updatedOrder);
    }

    return updatedOrder;
  }

  @override
  Future<Order> updateOrder(Order order) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = order.copyWith(updatedAt: DateTime.now());
    _orders[index] = updatedOrder;

    // Notify listeners if there's a stream for this order
    if (_orderControllers.containsKey(order.id)) {
      _orderControllers[order.id]!.add(updatedOrder);
    }

    return updatedOrder;
  }

  @override
  Stream<Order> orderUpdates(String orderId) {
    // Create a controller if it doesn't exist
    _orderControllers[orderId] ??= StreamController<Order>.broadcast();

    // Add the current order to the stream immediately if it exists
    try {
      final order = _orders.firstWhere((order) => order.id == orderId);
      Future.microtask(() => _orderControllers[orderId]!.add(order));
    } catch (e) {
      // Order not found - that's ok, will send updates when created
    }

    return _orderControllers[orderId]!.stream;
  }

  // Clean up resources
  void dispose() {
    for (final controller in _orderControllers.values) {
      controller.close();
    }
  }
}
