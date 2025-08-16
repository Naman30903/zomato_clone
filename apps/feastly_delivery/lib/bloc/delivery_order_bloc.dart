import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

// Events
abstract class DeliveryOrderEvent extends Equatable {
  const DeliveryOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchAssignedOrders extends DeliveryOrderEvent {
  final String deliveryPersonId;
  const FetchAssignedOrders(this.deliveryPersonId);

  @override
  List<Object?> get props => [deliveryPersonId];
}

class FetchOrderDetails extends DeliveryOrderEvent {
  final String orderId;
  const FetchOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class StartDelivery extends DeliveryOrderEvent {
  final String orderId;
  final String deliveryPersonId;
  const StartDelivery(this.orderId, this.deliveryPersonId);

  @override
  List<Object?> get props => [orderId, deliveryPersonId];
}

class MarkAsDelivered extends DeliveryOrderEvent {
  final String orderId;
  const MarkAsDelivered(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class TrackOrderUpdates extends DeliveryOrderEvent {
  final String orderId;
  const TrackOrderUpdates(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class StopOrderTracking extends DeliveryOrderEvent {}

class _OrderUpdated extends DeliveryOrderEvent {
  final Order order;
  const _OrderUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class _OrderTrackingError extends DeliveryOrderEvent {
  final String message;
  const _OrderTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

// States
abstract class DeliveryOrderState extends Equatable {
  const DeliveryOrderState();

  @override
  List<Object?> get props => [];
}

class DeliveryOrderInitial extends DeliveryOrderState {}

class DeliveryOrderLoading extends DeliveryOrderState {}

class AssignedOrdersLoaded extends DeliveryOrderState {
  final List<Order> orders;
  const AssignedOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderDetailsLoaded extends DeliveryOrderState {
  final Order order;
  const OrderDetailsLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class DeliveryOrderError extends DeliveryOrderState {
  final String message;
  const DeliveryOrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryActionSuccess extends DeliveryOrderState {
  final String message;
  const DeliveryActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DeliveryOrderBloc extends Bloc<DeliveryOrderEvent, DeliveryOrderState> {
  final OrderRepo orderRepo;
  StreamSubscription? _orderSubscription;

  DeliveryOrderBloc({required this.orderRepo}) : super(DeliveryOrderInitial()) {
    on<FetchAssignedOrders>(_onFetchAssignedOrders);
    on<FetchOrderDetails>(_onFetchOrderDetails);
    on<StartDelivery>(_onStartDelivery);
    on<MarkAsDelivered>(_onMarkAsDelivered);
    on<TrackOrderUpdates>(_onTrackOrderUpdates);
    on<StopOrderTracking>(_onStopOrderTracking);
    on<_OrderUpdated>(_onOrderUpdated);
    on<_OrderTrackingError>(_onOrderTrackingError);
  }

  Future<void> _onFetchAssignedOrders(
    FetchAssignedOrders event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(DeliveryOrderLoading());
    try {
      final orders = await orderRepo.getOrdersByDeliveryPerson(
        event.deliveryPersonId,
      );
      emit(AssignedOrdersLoaded(orders));
    } catch (e) {
      emit(
        DeliveryOrderError('Failed to load assigned orders: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetails event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(DeliveryOrderLoading());
    try {
      final order = await orderRepo.getOrderById(event.orderId);
      emit(OrderDetailsLoaded(order));
    } catch (e) {
      emit(DeliveryOrderError('Failed to load order details: ${e.toString()}'));
    }
  }

  Future<void> _onStartDelivery(
    StartDelivery event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(DeliveryOrderLoading());
    try {
      final updated = await orderRepo.assignDeliveryPerson(
        event.orderId,
        event.deliveryPersonId,
      );
      emit(DeliveryActionSuccess('Delivery started for ${updated.id}'));
      // optionally emit the new order details
      emit(OrderDetailsLoaded(updated));
    } catch (e) {
      emit(DeliveryOrderError('Failed to start delivery: $e'));
    }
  }

  Future<void> _onMarkAsDelivered(
    MarkAsDelivered event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(DeliveryOrderLoading());
    try {
      final updated = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.delivered,
      );
      emit(DeliveryActionSuccess('Order marked delivered'));
      emit(OrderDetailsLoaded(updated));
    } catch (e) {
      emit(DeliveryOrderError('Failed to mark delivered: $e'));
    }
  }

  Future<void> _onTrackOrderUpdates(
    TrackOrderUpdates event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    // cancel previous if any
    await _orderSubscription?.cancel();
    try {
      _orderSubscription = orderRepo
          .orderUpdates(event.orderId)
          .listen(
            (order) {
              add(_OrderUpdated(order));
            },
            onError: (e) {
              add(_OrderTrackingError(e.toString()));
            },
          );
      // Optionally load initial details
      final order = await orderRepo.getOrderById(event.orderId);
      add(_OrderUpdated(order));
    } catch (e) {
      emit(DeliveryOrderError('Failed to track order updates: $e'));
    }
  }

  Future<void> _onStopOrderTracking(
    StopOrderTracking event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    await _orderSubscription?.cancel();
    _orderSubscription = null;
    emit(DeliveryActionSuccess('Stopped tracking order updates'));
  }

  Future<void> _onOrderUpdated(
    _OrderUpdated event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(OrderDetailsLoaded(event.order));
  }

  Future<void> _onOrderTrackingError(
    _OrderTrackingError event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    emit(DeliveryOrderError('Order tracking error: ${event.message}'));
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}
