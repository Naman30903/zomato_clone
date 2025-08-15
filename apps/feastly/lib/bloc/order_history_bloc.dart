import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrderHistory extends OrderHistoryEvent {
  final String userId;
  final bool forceRefresh;

  const FetchOrderHistory({required this.userId, this.forceRefresh = false});

  @override
  List<Object?> get props => [userId, forceRefresh];
}

class FilterOrdersByStatus extends OrderHistoryEvent {
  final OrderStatus? status;

  const FilterOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

// States
abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<Order> orders;
  final List<Order> filteredOrders;
  final OrderStatus? filterStatus;

  const OrderHistoryLoaded({
    required this.orders,
    required this.filteredOrders,
    this.filterStatus,
  });

  @override
  List<Object?> get props => [orders, filteredOrders, filterStatus];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderRepo orderRepo;

  OrderHistoryBloc({required this.orderRepo}) : super(OrderHistoryInitial()) {
    on<FetchOrderHistory>(_onFetchOrderHistory);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
  }

  Future<void> _onFetchOrderHistory(
    FetchOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());

    try {
      final orders = await orderRepo.getOrdersByUser(event.userId);

      // Sort orders by creation date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(OrderHistoryLoaded(orders: orders, filteredOrders: orders));
    } catch (e) {
      emit(OrderHistoryError('Failed to load order history: ${e.toString()}'));
    }
  }

  void _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<OrderHistoryState> emit,
  ) {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;

      final filteredOrders = event.status == null
          ? currentState.orders
          : currentState.orders
                .where((order) => order.status == event.status)
                .toList();

      emit(
        OrderHistoryLoaded(
          orders: currentState.orders,
          filteredOrders: filteredOrders,
          filterStatus: event.status,
        ),
      );
    }
  }
}
