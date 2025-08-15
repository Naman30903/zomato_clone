import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddCartItem extends CartEvent {
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;
  final Map<String, dynamic> customizations;

  const AddCartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
    this.customizations = const {},
  });

  @override
  List<Object?> get props => [
    menuItem,
    quantity,
    specialInstructions,
    customizations,
  ];
}

class RemoveCartItem extends CartEvent {
  final String itemId;

  const RemoveCartItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class UpdateCartItemQuantity extends CartEvent {
  final String itemId;
  final int quantity;

  const UpdateCartItemQuantity({required this.itemId, required this.quantity});

  @override
  List<Object?> get props => [itemId, quantity];
}

class UpdateCartItemInstructions extends CartEvent {
  final String itemId;
  final String instructions;

  const UpdateCartItemInstructions({
    required this.itemId,
    required this.instructions,
  });

  @override
  List<Object?> get props => [itemId, instructions];
}

class ClearCart extends CartEvent {}

class ApplyCoupon extends CartEvent {
  final String couponCode;

  const ApplyCoupon(this.couponCode);

  @override
  List<Object?> get props => [couponCode];
}

class RemoveCoupon extends CartEvent {}

class UpdateDeliveryAddress extends CartEvent {
  final String address;

  const UpdateDeliveryAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdatePaymentMethod extends CartEvent {
  final PaymentMethod paymentMethod;

  const UpdatePaymentMethod(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

// States
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? restaurantId;
  final String? restaurantName;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String deliveryAddress;
  final PaymentMethod paymentMethod;

  const CartLoaded({
    required this.items,
    this.restaurantId,
    this.restaurantName,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    this.discount = 0,
    required this.total,
    this.couponCode,
    this.deliveryAddress = '',
    this.paymentMethod = PaymentMethod.creditCard,
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

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderRepo orderRepo;
  final RestaurantRepo restaurantRepo;
  static const double _taxRate = 0.08; // 8% tax rate
  static const double _deliveryFee = 2.99;
  final _uuid = const Uuid();

  CartBloc({required this.orderRepo, required this.restaurantRepo})
    : super(
        CartLoaded(items: [], subtotal: 0, tax: 0, deliveryFee: 0, total: 0),
      ) {
    on<AddCartItem>(_onAddCartItem);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<UpdateCartItemInstructions>(_onUpdateCartItemInstructions);
    on<ClearCart>(_onClearCart);
    on<ApplyCoupon>(_onApplyCoupon);
    on<RemoveCoupon>(_onRemoveCoupon);
    on<UpdateDeliveryAddress>(_onUpdateDeliveryAddress);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
  }

  Future<void> _onAddCartItem(
    AddCartItem event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      try {
        // Check if we're adding from a different restaurant
        if (currentState.restaurantId != null &&
            currentState.restaurantId != event.menuItem.restaurantId &&
            currentState.items.isNotEmpty) {
          // Ask user if they want to clear cart - this would be handled in UI
          emit(
            const CartError(
              'Items from different restaurants cannot be added to the same cart',
            ),
          );
          return;
        }

        // Get restaurant name if this is the first item
        String? restaurantName;
        if (currentState.restaurantId == null ||
            currentState.restaurantName == null) {
          try {
            final restaurant = await restaurantRepo.getRestaurantById(
              event.menuItem.restaurantId,
            );
            restaurantName = restaurant.name;
          } catch (e) {
            // Ignore error and continue without restaurant name
          }
        }

        // Check if item already exists in cart
        final existingItemIndex = currentState.items.indexWhere(
          (item) => item.menuItem.id == event.menuItem.id,
        );

        List<CartItem> updatedItems = List.from(currentState.items);

        if (existingItemIndex >= 0) {
          // Update existing item quantity
          final existingItem = currentState.items[existingItemIndex];
          updatedItems[existingItemIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + event.quantity,
          );
        } else {
          // Add new item
          updatedItems.add(
            CartItem(
              id: _uuid.v4(),
              menuItem: event.menuItem,
              quantity: event.quantity,
              specialInstructions: event.specialInstructions,
              customizations: event.customizations,
            ),
          );
        }

        // Calculate new totals
        final subtotal = _calculateSubtotal(updatedItems);
        final tax = subtotal * _taxRate;
        final deliveryFee = updatedItems.isEmpty ? 0 : _deliveryFee;
        final discount = currentState.discount;
        final total = subtotal + tax + deliveryFee - discount;

        emit(
          CartLoaded(
            items: updatedItems,
            restaurantId: event.menuItem.restaurantId,
            restaurantName: restaurantName ?? currentState.restaurantName,
            subtotal: subtotal,
            tax: tax,
            deliveryFee: deliveryFee.toDouble(),
            discount: discount,
            total: total,
            couponCode: currentState.couponCode,
            deliveryAddress: currentState.deliveryAddress,
            paymentMethod: currentState.paymentMethod,
          ),
        );
      } catch (e) {
        emit(CartError('Failed to add item to cart: ${e.toString()}'));
        emit(currentState); // Revert back to previous state
      }
    }
  }

  void _onRemoveCartItem(RemoveCartItem event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      try {
        // Remove the item
        final updatedItems = currentState.items
            .where((item) => item.id != event.itemId)
            .toList();

        // If cart is empty after removal, reset restaurant info
        final String? restaurantId = updatedItems.isEmpty
            ? null
            : currentState.restaurantId;
        final String? restaurantName = updatedItems.isEmpty
            ? null
            : currentState.restaurantName;

        // Calculate new totals
        final subtotal = _calculateSubtotal(updatedItems);
        final tax = subtotal * _taxRate;
        final deliveryFee = updatedItems.isEmpty ? 0 : _deliveryFee;
        final discount = currentState.discount;
        final total = subtotal + tax + deliveryFee - discount;

        emit(
          CartLoaded(
            items: updatedItems,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            subtotal: subtotal,
            tax: tax,
            deliveryFee: deliveryFee.toDouble(),
            discount: discount,
            total: total,
            couponCode: currentState.couponCode,
            deliveryAddress: currentState.deliveryAddress,
            paymentMethod: currentState.paymentMethod,
          ),
        );
      } catch (e) {
        emit(CartError('Failed to remove item from cart: ${e.toString()}'));
        emit(currentState); // Revert back to previous state
      }
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      try {
        // Find the item
        final itemIndex = currentState.items.indexWhere(
          (item) => item.id == event.itemId,
        );

        if (itemIndex == -1) {
          throw Exception('Item not found in cart');
        }

        List<CartItem> updatedItems = List.from(currentState.items);

        if (event.quantity <= 0) {
          // Remove the item if quantity is 0 or less
          updatedItems.removeAt(itemIndex);
        } else {
          // Update the quantity
          updatedItems[itemIndex] = currentState.items[itemIndex].copyWith(
            quantity: event.quantity,
          );
        }

        // If cart is empty after update, reset restaurant info
        final String? restaurantId = updatedItems.isEmpty
            ? null
            : currentState.restaurantId;
        final String? restaurantName = updatedItems.isEmpty
            ? null
            : currentState.restaurantName;

        // Calculate new totals
        final subtotal = _calculateSubtotal(updatedItems);
        final tax = subtotal * _taxRate;
        final deliveryFee = updatedItems.isEmpty ? 0 : _deliveryFee;
        final discount = currentState.discount;
        final total = subtotal + tax + deliveryFee - discount;

        emit(
          CartLoaded(
            items: updatedItems,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            subtotal: subtotal,
            tax: tax,
            deliveryFee: deliveryFee.toDouble(),
            discount: discount,
            total: total,
            couponCode: currentState.couponCode,
            deliveryAddress: currentState.deliveryAddress,
            paymentMethod: currentState.paymentMethod,
          ),
        );
      } catch (e) {
        emit(CartError('Failed to update item quantity: ${e.toString()}'));
        emit(currentState); // Revert back to previous state
      }
    }
  }

  void _onUpdateCartItemInstructions(
    UpdateCartItemInstructions event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      try {
        // Find the item
        final itemIndex = currentState.items.indexWhere(
          (item) => item.id == event.itemId,
        );

        if (itemIndex == -1) {
          throw Exception('Item not found in cart');
        }

        // Update the instructions
        final updatedItems = List<CartItem>.from(currentState.items);
        updatedItems[itemIndex] = currentState.items[itemIndex].copyWith(
          specialInstructions: event.instructions,
        );

        emit(
          CartLoaded(
            items: updatedItems,
            restaurantId: currentState.restaurantId,
            restaurantName: currentState.restaurantName,
            subtotal: currentState.subtotal,
            tax: currentState.tax,
            deliveryFee: currentState.deliveryFee,
            discount: currentState.discount,
            total: currentState.total,
            couponCode: currentState.couponCode,
            deliveryAddress: currentState.deliveryAddress,
            paymentMethod: currentState.paymentMethod,
          ),
        );
      } catch (e) {
        emit(CartError('Failed to update item instructions: ${e.toString()}'));
        emit(currentState); // Revert back to previous state
      }
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(
      const CartLoaded(
        items: [],
        subtotal: 0,
        tax: 0,
        deliveryFee: 0,
        total: 0,
      ),
    );
  }

  void _onApplyCoupon(ApplyCoupon event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      // In a real app, validate coupon with backend
      // For this mock, apply fixed discount
      double discount = 0;
      if (event.couponCode == 'WELCOME10') {
        discount = currentState.subtotal * 0.1; // 10% off
      } else if (event.couponCode == 'FLAT5') {
        discount = 5; // $5 off
      }

      final total =
          currentState.subtotal +
          currentState.tax +
          currentState.deliveryFee -
          discount;

      emit(
        CartLoaded(
          items: currentState.items,
          restaurantId: currentState.restaurantId,
          restaurantName: currentState.restaurantName,
          subtotal: currentState.subtotal,
          tax: currentState.tax,
          deliveryFee: currentState.deliveryFee,
          discount: discount,
          total: total,
          couponCode: event.couponCode,
          deliveryAddress: currentState.deliveryAddress,
          paymentMethod: currentState.paymentMethod,
        ),
      );
    }
  }

  void _onRemoveCoupon(RemoveCoupon event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      final total =
          currentState.subtotal + currentState.tax + currentState.deliveryFee;

      emit(
        CartLoaded(
          items: currentState.items,
          restaurantId: currentState.restaurantId,
          restaurantName: currentState.restaurantName,
          subtotal: currentState.subtotal,
          tax: currentState.tax,
          deliveryFee: currentState.deliveryFee,
          discount: 0,
          total: total,
          couponCode: null,
          deliveryAddress: currentState.deliveryAddress,
          paymentMethod: currentState.paymentMethod,
        ),
      );
    }
  }

  void _onUpdateDeliveryAddress(
    UpdateDeliveryAddress event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      emit(
        CartLoaded(
          items: currentState.items,
          restaurantId: currentState.restaurantId,
          restaurantName: currentState.restaurantName,
          subtotal: currentState.subtotal,
          tax: currentState.tax,
          deliveryFee: currentState.deliveryFee,
          discount: currentState.discount,
          total: currentState.total,
          couponCode: currentState.couponCode,
          deliveryAddress: event.address,
          paymentMethod: currentState.paymentMethod,
        ),
      );
    }
  }

  void _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;

      emit(
        CartLoaded(
          items: currentState.items,
          restaurantId: currentState.restaurantId,
          restaurantName: currentState.restaurantName,
          subtotal: currentState.subtotal,
          tax: currentState.tax,
          deliveryFee: currentState.deliveryFee,
          discount: currentState.discount,
          total: currentState.total,
          couponCode: currentState.couponCode,
          deliveryAddress: currentState.deliveryAddress,
          paymentMethod: event.paymentMethod,
        ),
      );
    }
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (item.menuItem.price * item.quantity),
    );
  }
}
