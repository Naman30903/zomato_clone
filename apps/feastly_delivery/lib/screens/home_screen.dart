import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  int _selectedIndex = 0;

  // sample deliveries
  final List<Map<String, String>> _deliveries = List.generate(6, (i) {
    return {
      "id": "#FD${1000 + i}",
      "pickup": "Restaurant ${String.fromCharCode(65 + i)}",
      "drop": "Customer ${i + 1}",
      "distance": "${(1.2 + i * 0.8).toStringAsFixed(1)} km",
      "reward": "\$${(3 + i * 1).toStringAsFixed(2)}",
    };
  });
  late final StreamController<List<Order>> _assignedOrdersController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _assignedOrdersController = StreamController<List<Order>>.broadcast();
    // Start initial fetch and polling after first frame so context.read works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndAddAssignedOrders();
      _startAssignedOrdersPolling();
    });
  }

  void _startAssignedOrdersPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchAndAddAssignedOrders();
    });
  }

  Future<void> _fetchAndAddAssignedOrders() async {
    try {
      final orderRepo = context.read<OrderRepo>();
      final orders = await orderRepo.getOrdersByDeliveryPerson('3');
      if (!_assignedOrdersController.isClosed) {
        _assignedOrdersController.add(orders);
      }
    } catch (e) {
      if (!_assignedOrdersController.isClosed) {
        _assignedOrdersController.addError(
          'Failed to load assigned orders: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _assignedOrdersController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top summary
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Avatar + greeting
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.delivery_dining,
                      color: const Color(0xFFf76b1c),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Good afternoon,",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Alex Rider",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Earnings card (compact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          "Today",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "\$48.20",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Online toggle
                  Column(
                    children: [
                      Switch(
                        value: _isOnline,
                        activeColor: const Color(0xFFf76b1c),
                        onChanged: (v) => setState(() => _isOnline = v),
                      ),
                      Text(
                        _isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          color: _isOnline ? Colors.green : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _QuickAction(
                    icon: Icons.play_arrow,
                    label: "Start Shift",
                    color: const Color(0xFFf76b1c),
                    onTap: () => setState(() => _isOnline = true),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.account_balance_wallet,
                    label: "Payouts",
                    color: Colors.blueAccent,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.history,
                    label: "History",
                    color: Colors.purple,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Active order / map preview area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _ActiveOrderPreview(isOnline: _isOnline),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder<List<Order>>(
                stream: _assignedOrdersController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                snapshot.error.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _fetchAndAddAssignedOrders,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SizedBox.shrink(); // no assigned orders yet
                  }

                  final orders = snapshot.data!;
                  if (orders.isEmpty) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_late,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No assigned orders. Go online to receive tasks.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final order = orders.first;
                  return GestureDetector(
                    onTap: () {
                      // Navigate to assigned order screen (route defined in main.dart)
                      context.go('/order/${order.id}');
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.12),
                              child: Icon(
                                Icons.local_shipping,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigned: Order ${order.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    order.deliveryAddress ?? 'Unknown address',
                                    style: TextStyle(color: Colors.grey[700]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            order.status,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _formatStatus(order.status),
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              order.status,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                context.go('/order/${order.id}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFf76b1c),
                              ),
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            // Available deliveries header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    "Available deliveries",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    "${_deliveries.length} nearby",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List of deliveries (expandable)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.separated(
                  itemCount: _deliveries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = _deliveries[index];
                    return _DeliveryCard(
                      id: d["id"]!,
                      pickup: d["pickup"]!,
                      drop: d["drop"]!,
                      distance: d["distance"]!,
                      reward: d["reward"]!,
                      onAccept: () {
                        context.go('/order/${d["id"]!}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Accepted ${d['id']}")),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // small map placeholder or info bar
            Container(
              height: 70,
              width: double.infinity,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: const [
                  Icon(Icons.map, color: Colors.black38),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Map preview • Live navigation available when you accept an order",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating action button to jump to active order / accept
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Go to Active"),
        icon: const Icon(Icons.navigation),
        backgroundColor: const Color(0xFFf76b1c),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFFf76b1c),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Orders",
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
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
      return 'Placed';
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(icon, color: color, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderPreview extends StatelessWidget {
  final bool isOnline;
  const _ActiveOrderPreview({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFf76b1c).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Color(0xFFf76b1c),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "No active order",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Go online to receive delivery requests",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: isOnline ? () {} : null,
              icon: const Icon(Icons.location_on),
              label: const Text("Go Online"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf76b1c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String id;
  final String pickup;
  final String drop;
  final String distance;
  final String reward;
  final VoidCallback onAccept;

  const _DeliveryCard({
    required this.id,
    required this.pickup,
    required this.drop,
    required this.distance,
    required this.reward,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: const Icon(Icons.restaurant, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$id • $distance",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$pickup → $drop",
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  reward,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf76b1c),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
