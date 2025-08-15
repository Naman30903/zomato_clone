import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

abstract class IncomingOrdersEvent extends Equatable {
  const IncomingOrdersEvent();
  @override
  List<Object?> get props => [];
}

class StartWatchingIncomingOrders extends IncomingOrdersEvent {
  final String restaurantId;
  const StartWatchingIncomingOrders(this.restaurantId);
  @override
  List<Object?> get props => [restaurantId];
}

class StopWatchingIncomingOrders extends IncomingOrdersEvent {}

class RefreshIncomingOrders extends IncomingOrdersEvent {}

abstract class IncomingOrdersState extends Equatable {
  const IncomingOrdersState();
  @override
  List<Object?> get props => [];
}

class IncomingOrdersInitial extends IncomingOrdersState {}

class IncomingOrdersLoading extends IncomingOrdersState {}

class IncomingOrdersLoaded extends IncomingOrdersState {
  final List<Order> orders;
  const IncomingOrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class IncomingOrdersError extends IncomingOrdersState {
  final String message;
  const IncomingOrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

class IncomingOrdersBloc
    extends Bloc<IncomingOrdersEvent, IncomingOrdersState> {
  final OrderRepo orderRepo;
  Timer? _pollTimer;
  String? _restaurantId;

  IncomingOrdersBloc({required this.orderRepo})
    : super(IncomingOrdersInitial()) {
    on<StartWatchingIncomingOrders>(_onStart);
    on<StopWatchingIncomingOrders>(_onStop);
    on<RefreshIncomingOrders>(_onRefresh);
  }

  Future<void> _onStart(
    StartWatchingIncomingOrders event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    _restaurantId = event.restaurantId;
    // Immediately refresh and then start polling
    add(RefreshIncomingOrders());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      add(RefreshIncomingOrders());
    });
  }

  Future<void> _onStop(
    StopWatchingIncomingOrders event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _restaurantId = null;
    emit(IncomingOrdersInitial());
  }

  Future<void> _onRefresh(
    RefreshIncomingOrders event,
    Emitter<IncomingOrdersState> emit,
  ) async {
    if (_restaurantId == null) return;
    emit(IncomingOrdersLoading());
    try {
      final orders = await orderRepo.getOrdersByRestaurant(_restaurantId!);
      // newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(IncomingOrdersLoaded(orders));
    } catch (e) {
      emit(
        IncomingOrdersError('Failed to load incoming orders: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
