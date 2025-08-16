import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';
import '../bloc/delivery_order_bloc.dart';
import 'package:feastly_delivery/bloc/delivery_status_bloc.dart';

class AssignedOrderScreen extends StatefulWidget {
  final String orderId;

  const AssignedOrderScreen({super.key, required this.orderId});

  @override
  State<AssignedOrderScreen> createState() => _AssignedOrderScreenState();
}

class _AssignedOrderScreenState extends State<AssignedOrderScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    context.read<DeliveryStatusBloc>().add(
      LoadDeliveryStatus(orderId: widget.orderId),
    );
  }

  void _loadOrderDetails() {
    context.read<DeliveryOrderBloc>().add(FetchOrderDetails(widget.orderId));
    context.read<DeliveryOrderBloc>().add(TrackOrderUpdates(widget.orderId));
  }

  @override
  void dispose() {
    context.read<DeliveryOrderBloc>().add(StopOrderTracking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${widget.orderId.substring(widget.orderId.length - 6)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: BlocListener<DeliveryStatusBloc, DeliveryStatusState>(
        listener: (context, state) {
          if (state is DeliveryStatusUpdateSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is DeliveryStatusError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocConsumer<DeliveryOrderBloc, DeliveryOrderState>(
          listener: (context, state) {
            if (state is DeliveryOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is DeliveryOrderLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrderDetailsLoaded) {
              return _buildOrderDetails(state.order);
            } else if (state is DeliveryOrderError) {
              return _buildErrorView(state.message);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹');

    return RefreshIndicator(
      onRefresh: () async {
        _loadOrderDetails();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderStatusCard(order),
              _buildStatusSlider(order),
              const SizedBox(height: 16),
              _buildRestaurantCard(order),
              const SizedBox(height: 16),
              _buildDeliveryDetailsCard(order),
              const SizedBox(height: 16),
              _buildOrderItemsCard(order),
              const SizedBox(height: 16),
              _buildPaymentCard(order, currencyFormatter),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSlider(Order order) {
    return BlocBuilder<DeliveryStatusBloc, DeliveryStatusState>(
      builder: (context, state) {
        double sliderValue = 0.0;

        if (state is DeliveryStatusLoaded) {
          sliderValue = state.sliderValue;
        } else if (state is DeliveryStatusUpdateSuccess) {
          sliderValue = state.sliderValue;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Order Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Ready for\nPickup',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Picked Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'In Transit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Delivered',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    trackHeight: 8,
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: Colors.orange,
                    overlayColor: Colors.orange.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 0.0,
                    max: 1.0,
                    divisions: 3,
                    onChanged: (value) {
                      final OrderStatus newStatus = _getStatusFromSliderValue(
                        value,
                      );

                      // Only allow forward progress
                      if (_isStatusProgressAllowed(order.status, newStatus)) {
                        context.read<DeliveryStatusBloc>().add(
                          UpdateOrderStatus(
                            orderId: order.id,
                            newStatus: newStatus,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You cannot revert order status'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  bool _isStatusProgressAllowed(
    OrderStatus currentStatus,
    OrderStatus newStatus,
  ) {
    final currentValue = _getStatusValue(currentStatus);
    final newValue = _getStatusValue(newStatus);
    return newValue >= currentValue;
  }

  int _getStatusValue(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForPickup:
        return 1;
      case OrderStatus.pickedUp:
        return 2;
      case OrderStatus.inTransit:
        return 3;
      case OrderStatus.delivered:
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildOrderStatusCard(Order order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      order.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created: ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Estimated Delivery: ${DateFormat('hh:mm a').format(order.estimatedDeliveryTime)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Order order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Restaurant Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.grey),
              ),
              title: Text(
                'Restaurant ID: ${order.restaurantId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          '123 Restaurant St, City',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        '+1 (555) 123-4567',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Navigate to restaurant on map
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.directions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard(Order order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Delivery Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            const Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Customer Name: John Doe',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivery Address: ${order.deliveryAddress}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Contact: +1 (555) 987-6543',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to customer location
                },
                icon: const Icon(Icons.directions),
                label: const Text('Navigate to Customer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(Order order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.circle, size: 8, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 20),
                    child: Text(
                      'Instructions: ${item.specialInstructions}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${(item.menuItem.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Order order, NumberFormat currencyFormatter) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Payment Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPaymentRow(
              'Item Total',
              currencyFormatter.format(order.subtotal),
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Delivery Fee',
              currencyFormatter.format(order.deliveryFee),
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Taxes & Charges',
              currencyFormatter.format(order.tax),
            ),
            const Divider(height: 16),
            _buildPaymentRow(
              'Grand Total',
              currencyFormatter.format(order.total),
              isBold: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getPaymentIcon(order.paymentMethod),
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method: ${_formatPaymentMethod(order.paymentMethod)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  order.isPaid ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: order.isPaid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Status: ${order.isPaid ? 'Paid' : 'Payment Due'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: order.isPaid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.indigo;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.readyForPickup:
        return Colors.amber;
      case OrderStatus.inTransit:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
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
        return 'Unknown';
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return Icons.payments_outlined;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.upi:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
