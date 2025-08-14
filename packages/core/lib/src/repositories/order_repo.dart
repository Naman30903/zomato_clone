import 'package:core/src/models/order.dart';
import 'package:core/src/models/enums.dart';

abstract class OrderRepo {
  Future<List<Order>> getOrdersByUser(String userId);
  Future<List<Order>> getOrdersByRestaurant(String restaurantId);
  Future<List<Order>> getOrdersByDeliveryPerson(String deliveryPersonId);
  Future<Order> getOrderById(String id);
  Future<Order> createOrder(Order order);
  Future<Order> updateOrderStatus(String orderId, OrderStatus status);
  Future<Order> assignDeliveryPerson(String orderId, String deliveryPersonId);
  Future<Order> updateOrder(Order order);
  Stream<Order> orderUpdates(String orderId);
}
