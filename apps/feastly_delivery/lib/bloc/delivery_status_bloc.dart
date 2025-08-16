import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

// Events
abstract class DeliveryStatusEvent extends Equatable {
  const DeliveryStatusEvent();

  @override
  List<Object?> get props => [];
}

class UpdateOrderStatus extends DeliveryStatusEvent {
  final String orderId;
  final OrderStatus newStatus;

  const UpdateOrderStatus({required this.orderId, required this.newStatus});

  @override
  List<Object?> get props => [orderId, newStatus];
}

class LoadDeliveryStatus extends DeliveryStatusEvent {
  final String orderId;

  const LoadDeliveryStatus({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

// States
abstract class DeliveryStatusState extends Equatable {
  const DeliveryStatusState();

  @override
  List<Object?> get props => [];
}

class DeliveryStatusInitial extends DeliveryStatusState {}

class DeliveryStatusLoading extends DeliveryStatusState {}

class DeliveryStatusLoaded extends DeliveryStatusState {
  final Order order;
  final double sliderValue;

  const DeliveryStatusLoaded({required this.order, required this.sliderValue});

  @override
  List<Object?> get props => [order, sliderValue];
}

class DeliveryStatusUpdateSuccess extends DeliveryStatusState {
  final Order order;
  final String message;
  final double sliderValue;

  const DeliveryStatusUpdateSuccess({
    required this.order,
    required this.message,
    required this.sliderValue,
  });

  @override
  List<Object?> get props => [order, message, sliderValue];
}

class DeliveryStatusError extends DeliveryStatusState {
  final String message;

  const DeliveryStatusError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DeliveryStatusBloc
    extends Bloc<DeliveryStatusEvent, DeliveryStatusState> {
  final OrderRepo orderRepo;

  DeliveryStatusBloc({required this.orderRepo})
    : super(DeliveryStatusInitial()) {
    on<LoadDeliveryStatus>(_onLoadDeliveryStatus);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  Future<void> _onLoadDeliveryStatus(
    LoadDeliveryStatus event,
    Emitter<DeliveryStatusState> emit,
  ) async {
    emit(DeliveryStatusLoading());
    try {
      final order = await orderRepo.getOrderById(event.orderId);
      emit(
        DeliveryStatusLoaded(
          order: order,
          sliderValue: _getSliderValueFromStatus(order.status),
        ),
      );
    } catch (e) {
      emit(DeliveryStatusError('Failed to load order status: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<DeliveryStatusState> emit,
  ) async {
    final currentState = state;
    if (currentState is DeliveryStatusLoaded ||
        currentState is DeliveryStatusUpdateSuccess) {
      emit(DeliveryStatusLoading());
      try {
        final updatedOrder = await orderRepo.updateOrderStatus(
          event.orderId,
          event.newStatus,
        );

        final sliderValue = _getSliderValueFromStatus(event.newStatus);

        emit(
          DeliveryStatusUpdateSuccess(
            order: updatedOrder,
            message:
                'Order status updated to ${_formatStatus(event.newStatus)}',
            sliderValue: sliderValue,
          ),
        );
      } catch (e) {
        emit(DeliveryStatusError('Failed to update status: ${e.toString()}'));
      }
    }
  }

  // Helper methods
  double _getSliderValueFromStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForPickup:
        return 0.0;
      case OrderStatus
          .pickedUp: // This might need to be added to your OrderStatus enum
        return 0.33;
      case OrderStatus.inTransit:
        return 0.67;
      case OrderStatus.delivered:
        return 1.0;
      default:
        return 0.0; // Default to ready for pickup
    }
  }

  OrderStatus _getStatusFromSliderValue(double value) {
    if (value < 0.25) {
      return OrderStatus.readyForPickup;
    } else if (value < 0.50) {
      return OrderStatus.pickedUp;
    } else if (value < 0.75) {
      return OrderStatus.inTransit;
    } else {
      return OrderStatus.delivered;
    }
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return status.toString().split('.').last;
    }
  }
}
