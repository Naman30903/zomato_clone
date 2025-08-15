import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderStatusTimeline extends StatelessWidget {
  final Order order;

  const OrderStatusTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];

    // Handle cancelled orders
    if (order.status == OrderStatus.cancelled) {
      return _buildCancelledTimeline(context);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...List.generate(statuses.length, (index) {
              final status = statuses[index];
              final isActive = _getStatusIndex(order.status) >= index;
              final isCurrentStatus = order.status == status;

              return TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.2,
                isFirst: index == 0,
                isLast: index == statuses.length - 1,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  height: 20,
                  indicator: _buildIndicator(isActive, isCurrentStatus),
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                beforeLineStyle: LineStyle(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                afterLineStyle: LineStyle(
                  color: index < _getStatusIndex(order.status)
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                endChild: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatStatus(status),
                        style: TextStyle(
                          fontWeight: isCurrentStatus
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentStatus
                              ? Theme.of(context).primaryColor
                              : isActive
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      if (isCurrentStatus || (index == 0 && isActive))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _getTimeForStatus(index, isCurrentStatus),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledTimeline(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.2,
              isFirst: true,
              isLast: false,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: _buildIndicator(true, false),
                color: Theme.of(context).primaryColor,
              ),
              beforeLineStyle: LineStyle(color: Theme.of(context).primaryColor),
              afterLineStyle: const LineStyle(color: Colors.red),
              endChild: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Placed'),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('hh:mm a').format(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.2,
              isFirst: false,
              isLast: true,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                indicator: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
              beforeLineStyle: const LineStyle(color: Colors.red),
              endChild: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Cancelled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('hh:mm a').format(order.updatedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive, bool isCurrentStatus) {
    if (isCurrentStatus) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 4),
        ),
      );
    } else if (isActive) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 12),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  String _getTimeForStatus(int statusIndex, bool isCurrentStatus) {
    // For order placed status, always use createdAt
    if (statusIndex == 0) {
      return DateFormat('hh:mm a').format(order.createdAt);
    }

    // For current status, use updatedAt
    if (isCurrentStatus) {
      return DateFormat('hh:mm a').format(order.updatedAt);
    }

    // For other statuses, don't show time
    return '';
  }

  int _getStatusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.readyForPickup:
        return 3;
      case OrderStatus.inTransit:
        return 4;
      case OrderStatus.delivered:
        return 5;
      default:
        return -1;
    }
  }

  String _formatStatus(OrderStatus status) {
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
        return status.toString().split('.').last;
    }
  }
}
