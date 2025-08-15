import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class PlaceOrder extends OrderEvent {
  final List<CartItem> items;
  final String restaurantId;
  final String restaurantName;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String deliveryAddress;
  final PaymentMethod paymentMethod;

  const PlaceOrder({
    required this.items,
    required this.restaurantId,
    required this.restaurantName,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.couponCode,
    required this.deliveryAddress,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    items,
    restaurantId,
    restaurantName,
    subtotal,
    tax,
    deliveryFee,
    discount,
    total,
    couponCode,
    deliveryAddress,
    paymentMethod,
  ];
}

class CancelOrder extends OrderEvent {
  final String orderId;

  const CancelOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class TrackOrder extends OrderEvent {
  final String orderId;

  const TrackOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// States
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderPlacing extends OrderState {}

class OrderPlaced extends OrderState {
  final Order order;

  const OrderPlaced(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderTracking extends OrderState {
  final Order order;

  const OrderTracking(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepo orderRepo;
  final _uuid = const Uuid();
  StreamSubscription? _orderSubscription;

  OrderBloc({required this.orderRepo}) : super(OrderInitial()) {
    on<PlaceOrder>(_onPlaceOrder);
    on<CancelOrder>(_onCancelOrder);
    on<TrackOrder>(_onTrackOrder);
  }

  Future<void> _onPlaceOrder(PlaceOrder event, Emitter<OrderState> emit) async {
    emit(OrderPlacing());

    try {
      // Create order from cart data
      final order = Order(
        id: 'temp_${_uuid.v4()}', // Temporary ID that will be replaced by backend
        userId: '1', // Normally would come from authentication service
        restaurantId: event.restaurantId,
        items: event.items,
        subtotal: event.subtotal,
        tax: event.tax,
        deliveryFee: event.deliveryFee,
        total: event.total,
        status: OrderStatus.placed,
        deliveryAddress: event.deliveryAddress,
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 45)),
        paymentMethod: event.paymentMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Submit to repository
      final placedOrder = await orderRepo.createOrder(order);

      // Start tracking the order
      _trackOrderUpdates(placedOrder.id);

      emit(OrderPlaced(placedOrder));
    } catch (e) {
      emit(OrderError('Failed to place order: ${e.toString()}'));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // Get the current order
      final order = await orderRepo.getOrderById(event.orderId);

      // Verify it can be canceled (only if in certain statuses)
      if (order.status != OrderStatus.placed &&
          order.status != OrderStatus.confirmed &&
          order.status != OrderStatus.preparing) {
        emit(OrderError('This order cannot be canceled anymore'));
        return;
      }

      // Update status to canceled
      final updatedOrder = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.cancelled,
      );

      emit(OrderPlaced(updatedOrder));
    } catch (e) {
      emit(OrderError('Failed to cancel order: ${e.toString()}'));
    }
  }

  Future<void> _onTrackOrder(TrackOrder event, Emitter<OrderState> emit) async {
    try {
      final order = await orderRepo.getOrderById(event.orderId);
      _trackOrderUpdates(event.orderId);
      emit(OrderTracking(order));
    } catch (e) {
      emit(OrderError('Failed to track order: ${e.toString()}'));
    }
  }

  void _trackOrderUpdates(String orderId) {
    // Cancel any existing subscription
    _orderSubscription?.cancel();

    // Subscribe to order updates
    _orderSubscription = orderRepo
        .orderUpdates(orderId)
        .listen(
          (updatedOrder) {
            // Emit the updated order state
            emit(OrderTracking(updatedOrder));
          },
          onError: (error) {
            emit(OrderError('Error tracking order: ${error.toString()}'));
          },
        );
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}
