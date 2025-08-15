import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

// Events
abstract class OrderActionEvent extends Equatable {
  const OrderActionEvent();

  @override
  List<Object?> get props => [];
}

class AcceptOrder extends OrderActionEvent {
  final String orderId;

  const AcceptOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class RejectOrder extends OrderActionEvent {
  final String orderId;
  final String? reason;

  const RejectOrder(this.orderId, {this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class StartPreparingOrder extends OrderActionEvent {
  final String orderId;

  const StartPreparingOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class MarkOrderReady extends OrderActionEvent {
  final String orderId;

  const MarkOrderReady(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class HandoverOrderToDelivery extends OrderActionEvent {
  final String orderId;
  final String deliveryPersonId;

  const HandoverOrderToDelivery(this.orderId, this.deliveryPersonId);

  @override
  List<Object> get props => [orderId, deliveryPersonId];
}

class CancelOrder extends OrderActionEvent {
  final String orderId;
  final String reason;

  const CancelOrder(this.orderId, this.reason);

  @override
  List<Object> get props => [orderId, reason];
}

// States
abstract class OrderActionState extends Equatable {
  const OrderActionState();

  @override
  List<Object?> get props => [];
}

class OrderActionInitial extends OrderActionState {}

class OrderActionInProgress extends OrderActionState {}

class OrderActionSuccess extends OrderActionState {
  final Order order;
  final String message;

  const OrderActionSuccess({required this.order, required this.message});

  @override
  List<Object> get props => [order, message];
}

class OrderActionFailure extends OrderActionState {
  final String message;

  const OrderActionFailure(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class OrderActionsBloc extends Bloc<OrderActionEvent, OrderActionState> {
  final OrderRepo orderRepo;

  OrderActionsBloc({required this.orderRepo}) : super(OrderActionInitial()) {
    on<AcceptOrder>(_onAcceptOrder);
    on<RejectOrder>(_onRejectOrder);
    on<StartPreparingOrder>(_onStartPreparingOrder);
    on<MarkOrderReady>(_onMarkOrderReady);
    on<HandoverOrderToDelivery>(_onHandoverOrderToDelivery);
    on<CancelOrder>(_onCancelOrder);
  }

  Future<void> _onAcceptOrder(
    AcceptOrder event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      final updatedOrder = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.confirmed,
      );
      emit(
        OrderActionSuccess(
          order: updatedOrder,
          message: 'Order accepted successfully',
        ),
      );
    } catch (e) {
      emit(OrderActionFailure('Failed to accept order: ${e.toString()}'));
    }
  }

  Future<void> _onRejectOrder(
    RejectOrder event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      final order = await orderRepo.getOrderById(event.orderId);
      final updatedOrder = order.copyWith(
        status: OrderStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      final result = await orderRepo.updateOrder(updatedOrder);
      emit(OrderActionSuccess(order: result, message: 'Order rejected'));
    } catch (e) {
      emit(OrderActionFailure('Failed to reject order: ${e.toString()}'));
    }
  }

  Future<void> _onStartPreparingOrder(
    StartPreparingOrder event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      final updatedOrder = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.preparing,
      );
      emit(
        OrderActionSuccess(
          order: updatedOrder,
          message: 'Order is now being prepared',
        ),
      );
    } catch (e) {
      emit(
        OrderActionFailure('Failed to update order status: ${e.toString()}'),
      );
    }
  }

  Future<void> _onMarkOrderReady(
    MarkOrderReady event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      final updatedOrder = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.readyForPickup,
      );
      emit(
        OrderActionSuccess(
          order: updatedOrder,
          message: 'Order is ready for pickup',
        ),
      );
    } catch (e) {
      emit(
        OrderActionFailure('Failed to mark order as ready: ${e.toString()}'),
      );
    }
  }

  Future<void> _onHandoverOrderToDelivery(
    HandoverOrderToDelivery event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      await orderRepo.assignDeliveryPerson(
        event.orderId,
        event.deliveryPersonId,
      );

      final updatedOrder = await orderRepo.updateOrderStatus(
        event.orderId,
        OrderStatus.inTransit,
      );

      emit(
        OrderActionSuccess(
          order: updatedOrder,
          message: 'Order handed over to delivery',
        ),
      );
    } catch (e) {
      emit(OrderActionFailure('Failed to handover order: ${e.toString()}'));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderActionState> emit,
  ) async {
    emit(OrderActionInProgress());
    try {
      final order = await orderRepo.getOrderById(event.orderId);
      final updatedOrder = order.copyWith(
        status: OrderStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      final result = await orderRepo.updateOrder(updatedOrder);
      emit(OrderActionSuccess(order: result, message: 'Order cancelled'));
    } catch (e) {
      emit(OrderActionFailure('Failed to cancel order: ${e.toString()}'));
    }
  }
}
