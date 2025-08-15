import 'package:feastly/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:feastly/bloc/cart_bloc.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  String? _editingInstructionsFor;

  @override
  void dispose() {
    _couponController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          // The order was successfully placed
          // We'll handle this in the order confirmation dialog
        } else if (state is OrderError) {
          // Show error message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your Cart',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoaded && state.items.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showClearCartDialog(context),
                    tooltip: 'Clear cart',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CartLoaded) {
              if (state.items.isEmpty) {
                return _buildEmptyCart();
              }
              return _buildCartContent(state);
            } else if (state is CartError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CartBloc>().add(ClearCart());
                      },
                      child: const Text('Clear Cart and Try Again'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Looks like you haven\'t added anything to your cart yet',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.restaurant),
            label: const Text('Browse Restaurants'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartLoaded state) {
    return Column(
      children: [
        if (state.restaurantName != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your order from',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      Text(
                        state.restaurantName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              // Cart items
              ...state.items.map((item) => _buildCartItem(item)).toList(),

              // Coupon section
              _buildCouponSection(state),

              // Address section
              _buildAddressSection(state),

              // Payment method section
              _buildPaymentMethodSection(state),

              // Order summary
              _buildOrderSummary(state),
            ],
          ),
        ),

        // Checkout button
        _buildCheckoutButton(state),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<CartBloc>().add(RemoveCartItem(item.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.menuItem.name} removed from cart'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                context.read<CartBloc>().add(
                  AddCartItem(
                    menuItem: item.menuItem,
                    quantity: item.quantity,
                    specialInstructions: item.specialInstructions,
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.menuItem.imageUrls.isNotEmpty
                      ? item.menuItem.imageUrls
                      : 'https://via.placeholder.com/80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Row(
                      children: [
                        Container(
                          height: 16,
                          width: 16,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.menuItem.isVegetarian
                                  ? Colors.green
                                  : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: item.menuItem.isVegetarian
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.menuItem.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Item price
                    Text(
                      '₹${item.menuItem.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Special instructions
                    if (item.specialInstructions != null &&
                        item.specialInstructions!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.specialInstructions!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Edit instructions button
                    TextButton.icon(
                      onPressed: () => _showInstructionsDialog(context, item),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        item.specialInstructions == null ||
                                item.specialInstructions!.isEmpty
                            ? 'Add instructions'
                            : 'Edit instructions',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity controls
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrement button
                        InkWell(
                          onTap: item.quantity > 1
                              ? () => context.read<CartBloc>().add(
                                  UpdateCartItemQuantity(
                                    itemId: item.id,
                                    quantity: item.quantity - 1,
                                  ),
                                )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: item.quantity > 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        // Quantity display
                        Container(
                          constraints: const BoxConstraints(minWidth: 30),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Increment button
                        InkWell(
                          onTap: () => context.read<CartBloc>().add(
                            UpdateCartItemQuantity(
                              itemId: item.id,
                              quantity: item.quantity + 1,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${(item.menuItem.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[400],
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    splashRadius: 24,
                    onPressed: () =>
                        context.read<CartBloc>().add(RemoveCartItem(item.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.local_offer_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Apply Coupon',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: state.couponCode != null
                ? Text(
                    'Code: ${state.couponCode}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
            trailing: state.couponCode != null
                ? TextButton(
                    onPressed: () {
                      context.read<CartBloc>().add(RemoveCoupon());
                    },
                    child: const Text('REMOVE'),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _showCouponDialog(context),
                  ),
            onTap: () {
              if (state.couponCode == null) {
                _showCouponDialog(context);
              }
            },
          ),
          if (state.couponCode != null && state.discount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount applied',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  Text(
                    '-₹${state.discount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(CartLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'Delivery Address',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: state.deliveryAddress.isNotEmpty
            ? Text(state.deliveryAddress)
            : const Text(
                'Add your delivery address',
                style: TextStyle(color: Colors.grey),
              ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showAddressDialog(context, state.deliveryAddress),
      ),
    );
  }

  Widget _buildPaymentMethodSection(CartLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.payment_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatPaymentMethod(state.paymentMethod)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showPaymentMethodDialog(context, state.paymentMethod),
      ),
    );
  }

  Widget _buildOrderSummary(CartLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBillRow('Item Total', '₹${state.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildBillRow(
            'Delivery Fee',
            '₹${state.deliveryFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildBillRow('Taxes', '₹${state.tax.toStringAsFixed(2)}'),
          if (state.discount > 0) ...[
            const SizedBox(height: 8),
            _buildBillRow(
              'Discount',
              '-₹${state.discount.toStringAsFixed(2)}',
              valueColor: Colors.green[700],
            ),
          ],
          const Divider(height: 24),
          _buildBillRow(
            'Total',
            '₹${state.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(CartLoaded state) {
    bool canCheckout =
        state.items.isNotEmpty && state.deliveryAddress.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: canCheckout
            ? () {
                // Create order logic
                _showOrderConfirmationDialog(context, state);
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              canCheckout
                  ? 'Place Order • ₹${state.total.toStringAsFixed(2)}'
                  : state.deliveryAddress.isEmpty
                  ? 'Add delivery address to continue'
                  : 'Place Order',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Apply Coupon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final code = _couponController.text.trim();
                  if (code.isNotEmpty) {
                    context.read<CartBloc>().add(ApplyCoupon(code));
                    _couponController.clear();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('APPLY'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Available coupons:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildCouponCard(
                'WELCOME10',
                '10% off on your first order',
                'Min order: ₹300',
              ),
              const SizedBox(height: 8),
              _buildCouponCard(
                'FLAT5',
                'Flat ₹5 off on all orders',
                'No minimum order value',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(String code, String description, String terms) {
    return GestureDetector(
      onTap: () {
        _couponController.text = code;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.percent,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    terms,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                _couponController.text = code;
                context.read<CartBloc>().add(ApplyCoupon(code));
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('APPLY'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, String currentAddress) {
    _addressController.text = currentAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter your complete address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final address = _addressController.text.trim();
                  if (address.isNotEmpty) {
                    context.read<CartBloc>().add(
                      UpdateDeliveryAddress(address),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('SAVE ADDRESS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(
    BuildContext context,
    PaymentMethod currentMethod,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                context,
                PaymentMethod.cashOnDelivery,
                'Cash on Delivery',
                Icons.payments_outlined,
                currentMethod,
              ),
              _buildPaymentOption(
                context,
                PaymentMethod.creditCard,
                'Credit/Debit Card',
                Icons.credit_card,
                currentMethod,
              ),
              _buildPaymentOption(
                context,
                PaymentMethod.upi,
                'UPI',
                Icons.account_balance_wallet_outlined,
                currentMethod,
              ),
              _buildPaymentOption(
                context,
                PaymentMethod.wallet,
                'Digital Wallet',
                Icons.account_balance_wallet,
                currentMethod,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    PaymentMethod method,
    String label,
    IconData icon,
    PaymentMethod currentMethod,
  ) {
    final isSelected = method == currentMethod;

    return InkWell(
      onTap: () {
        context.read<CartBloc>().add(UpdatePaymentMethod(method));
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[700],
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context, CartItem item) {
    _instructionsController.text = item.specialInstructions ?? '';
    _editingInstructionsFor = item.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Special Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    item.menuItem.name,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  hintText: 'E.g., no onions, extra spicy, etc.',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_editingInstructionsFor != null) {
                    context.read<CartBloc>().add(
                      UpdateCartItemInstructions(
                        itemId: _editingInstructionsFor!,
                        instructions: _instructionsController.text.trim(),
                      ),
                    );
                    _instructionsController.clear();
                    _editingInstructionsFor = null;
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('SAVE INSTRUCTIONS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderConfirmationDialog(BuildContext context, CartLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to place this order?'),
            const SizedBox(height: 16),
            Text(
              'Total: ₹${state.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Payment: ${_formatPaymentMethod(state.paymentMethod)}'),
            const SizedBox(height: 8),
            const Text(
              'Your order will be delivered to:',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              state.deliveryAddress,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (state.restaurantId != null) {
                // Close the dialog
                Navigator.pop(dialogContext);

                // Show a loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // Dispatch the PlaceOrder event
                context.read<OrderBloc>().add(
                  PlaceOrder(
                    items: state.items,
                    restaurantId: state.restaurantId!,
                    restaurantName: state.restaurantName ?? 'Restaurant',
                    subtotal: state.subtotal,
                    tax: state.tax,
                    deliveryFee: state.deliveryFee,
                    discount: state.discount,
                    total: state.total,
                    couponCode: state.couponCode,
                    deliveryAddress: state.deliveryAddress,
                    paymentMethod: state.paymentMethod,
                  ),
                );

                // Listen for the OrderBloc state changes
                context.read<OrderBloc>().stream.listen((state) {
                  if (state is OrderPlaced) {
                    // Close the loading dialog
                    Navigator.pop(context);

                    // Clear the cart
                    context.read<CartBloc>().add(ClearCart());

                    // Show success dialog with the order ID
                    _showOrderSuccessDialog(context, state.order);
                  } else if (state is OrderError) {
                    // Close the loading dialog
                    Navigator.pop(context);

                    // Show error message
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                });
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('PLACE ORDER'),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Order Placed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your order has been placed successfully!'),
            const SizedBox(height: 16),
            Text('Order #${order.id}'),
            const SizedBox(height: 8),
            const Text(
              'You can track your order status in the Orders section.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to order tracking screen
              context.go('/order/${order.id}');
            },
            child: const Text('TRACK ORDER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/home');
            },
            child: const Text('CONTINUE SHOPPING'),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'Credit/Debit Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      default:
        return 'Cash on Delivery';
    }
  }
}
