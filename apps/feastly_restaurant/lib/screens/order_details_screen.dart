import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';
import '../bloc/order_action_bloc.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Order> _orderFuture;
  final _rejectionReasonController = TextEditingController();
  final _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    _orderFuture = context.read<OrderRepo>().getOrderById(widget.orderId);
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadOrderDetails();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load order details',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadOrderDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Order not found'));
          }

          final order = snapshot.data!;
          return BlocListener<OrderActionsBloc, OrderActionState>(
            listener: (context, state) {
              if (state is OrderActionSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                setState(() {
                  _loadOrderDetails();
                });
              } else if (state is OrderActionFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadOrderDetails();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderStatusHeader(order),
                    const SizedBox(height: 24),
                    OrderStatusTimeline(order: order),
                    // const SizedBox(height: 24),
                    // _buildCustomerInfo(order),
                    const SizedBox(height: 24),
                    _buildOrderItems(order),
                    const SizedBox(height: 16),
                    _buildOrderSummary(order),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, order),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderStatusHeader(Order order) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.15),
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
            if (order.status == OrderStatus.cancelled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Reason:  Not specified',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildCustomerInfo(Order order) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Customer Information',
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 16,
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           _buildInfoRow(
  //             Icons.person_outline,
  //             order.,
  //           ),
  //           const SizedBox(height: 8),
  //           _buildInfoRow(
  //             Icons.phone_outlined,
  //             order.user.phoneNumber,
  //             isPhoneNumber: true,
  //           ),
  //           const SizedBox(height: 8),
  //           _buildInfoRow(
  //             Icons.location_on_outlined,
  //             order.deliveryAddress,
  //           ),
  //           const SizedBox(height: 8),
  //           _buildInfoRow(
  //             Icons.note_outlined,
  //             order.specialInstructions ?? 'No special instructions',
  //             color: order.specialInstructions != null
  //                 ? Colors.black
  //                 : Colors.grey,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    bool isPhoneNumber = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: isPhoneNumber
              ? GestureDetector(
                  onTap: () {
                    // Launch phone call
                  },
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }

  Widget _buildOrderItems(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${order.items.length} items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.menuItem.isVegetarian
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.circle,
              size: 8,
              color: item.menuItem.isVegetarian ? Colors.green : Colors.red,
            ),
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
                if (item.customizations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 20),
                    child: Text(
                      'Customizations: ${item.customizations.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
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
            currencyFormatter.format(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Item Total',
              currencyFormatter.format(order.subtotal),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Delivery Fee',
              currencyFormatter.format(order.deliveryFee),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Taxes & Charges',
              currencyFormatter.format(order.tax),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Grand Total',
              currencyFormatter.format(order.total),
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Payment Method',
              _formatPaymentMethod(order.paymentMethod),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Payment Status',
              _formatPaymentStatus(order.isPaid),
              valueColor: order.isPaid ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
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
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Order order) {
    // Different buttons based on order status
    switch (order.status) {
      case OrderStatus.placed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRejectDialog(context, order.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Reject Order'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<OrderActionsBloc>().add(AcceptOrder(order.id));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Accept Order'),
              ),
            ),
          ],
        );

      case OrderStatus.confirmed:
        return ElevatedButton(
          onPressed: () {
            context.read<OrderActionsBloc>().add(StartPreparingOrder(order.id));
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Start Preparing'),
        );

      case OrderStatus.preparing:
        return ElevatedButton(
          onPressed: () {
            context.read<OrderActionsBloc>().add(MarkOrderReady(order.id));
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Mark as Ready for Pickup'),
        );

      case OrderStatus.readyForPickup:
        return ElevatedButton(
          onPressed: () {
            // In a real app, you'd show a delivery person selector
            // For now, we'll use a dummy delivery person ID
            context.read<OrderActionsBloc>().add(
              HandoverOrderToDelivery(order.id, 'delivery_1'),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Hand Over to Delivery'),
        );

      case OrderStatus.inTransit:
      case OrderStatus.delivered:
        return const SizedBox.shrink(); // No actions needed

      case OrderStatus.cancelled:
        return const SizedBox.shrink(); // No actions needed

      default:
        if (order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled) {
          return OutlinedButton(
            onPressed: () => _showCancelDialog(context, order.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Cancel Order'),
          );
        }
        return const SizedBox.shrink();
    }
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejecting this order:'),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectionReasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_rejectionReasonController.text.trim().isNotEmpty) {
                  context.read<OrderActionsBloc>().add(
                    RejectOrder(
                      orderId,
                      reason: _rejectionReasonController.text.trim(),
                    ),
                  );
                  _rejectionReasonController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for rejection'),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for cancelling this order:'),
              const SizedBox(height: 16),
              TextField(
                controller: _cancelReasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_cancelReasonController.text.trim().isNotEmpty) {
                  context.read<OrderActionsBloc>().add(
                    CancelOrder(orderId, _cancelReasonController.text.trim()),
                  );
                  _cancelReasonController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for cancellation'),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
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
    return status.toString().split('.').last.toUpperCase();
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.upi:
        return 'UPI';
      default:
        return 'Unknown';
    }
  }

  String _formatPaymentStatus(bool isPaid) {
    return isPaid ? 'Paid' : 'Unpaid';
  }
}
