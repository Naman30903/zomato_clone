import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:feastly/bloc/order_history_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    context.read<OrderHistoryBloc>().add(const FetchOrderHistory(userId: '1'));

    _tabController.addListener(() {
      OrderStatus? filterStatus;

      switch (_tabController.index) {
        case 0: // All
          filterStatus = null;
          break;
        case 1: // Active
          filterStatus = OrderStatus.placed;
          break;
        case 2: // In Progress
          filterStatus = OrderStatus.preparing;
          break;
        case 3: // Completed
          filterStatus = OrderStatus.delivered;
          break;
        case 4: // Cancelled
          filterStatus = OrderStatus.cancelled;
          break;
      }

      context.read<OrderHistoryBloc>().add(FilterOrdersByStatus(filterStatus));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
        builder: (context, state) {
          if (state is OrderHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrderHistoryLoaded) {
            if (state.filteredOrders.isEmpty) {
              return _buildEmptyState();
            }
            return _buildOrderList(state.filteredOrders);
          } else if (state is OrderHistoryError) {
            return _buildErrorState(state.message);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your order history will appear here',
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<OrderHistoryBloc>().add(
                const FetchOrderHistory(userId: '1', forceRefresh: true),
              );
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderHistoryBloc>().add(
          const FetchOrderHistory(userId: '1', forceRefresh: true),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/order/${order.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getStatusColor(order.status),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Order #${order.id.substring(order.id.length - 6)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Restaurant name and date
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order from Restaurant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timeago.format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Order items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display first 2 items + show more if there are more
                  ...order.items
                      .take(2)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${item.quantity}x ${item.menuItem.name}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                  if (order.items.length > 2)
                    Text(
                      '+${order.items.length - 2} more items',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                ],
              ),
            ),

            // Order total and action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.delivered)
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement reorder functionality
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reorder'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/order/${order.id}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: const Text('Track Order'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.blue[700]!;
      case OrderStatus.preparing:
        return Colors.orange[700]!;
      case OrderStatus.readyForPickup:
        return Colors.amber[700]!;
      case OrderStatus.inTransit:
        return Colors.purple[700]!;
      case OrderStatus.delivered:
        return Colors.green[700]!;
      case OrderStatus.cancelled:
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.inTransit:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }
}
