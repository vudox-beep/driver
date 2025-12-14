import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<Order>? onSelectOrder;
  final VoidCallback? goToDetails;
  final VoidCallback? goToNavigate;
  const DashboardScreen({
    super.key,
    this.onSelectOrder,
    this.goToDetails,
    this.goToNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool available = true;
  String filter = 'all';
  bool notificationsEnabled = true;
  final orders = <Order>[
    const Order(
      id: 'ORD-1001',
      customerName: 'Alex Johnson',
      pickupAddress: '12 Market St',
      deliveryAddress: '45 Pine Ave',
      status: 'awaiting',
      payout: 12.50,
    ),
    const Order(
      id: 'ORD-1002',
      customerName: 'Maria Gomez',
      pickupAddress: '88 River Rd',
      deliveryAddress: '3 Sunset Blvd',
      status: 'in_progress',
      payout: 18.25,
    ),
    const Order(
      id: 'ORD-1003',
      customerName: 'Samir Khan',
      pickupAddress: '101 Cedar Ln',
      deliveryAddress: '6 Oak St',
      status: 'delivered',
      payout: 9.75,
    ),
  ];

  double get earningsToday => orders
      .where((o) => o.status == 'delivered')
      .fold(0.0, (sum, o) => sum + o.payout);

  int get deliveredCount => orders.where((o) => o.status == 'delivered').length;

  List<Order> get filteredOrders {
    switch (filter) {
      case 'active':
        return orders.where((o) => o.status != 'delivered').toList();
      case 'delivered':
        return orders.where((o) => o.status == 'delivered').toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Home')),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Driver Home', style: TextStyle(fontSize: 20)),
                  Row(
                    children: [
                      Text(available ? 'Available' : 'Offline'),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => setState(() => available = !available),
                        icon: Icon(
                          available ? Icons.toggle_on : Icons.toggle_off,
                        ),
                        color: AppTheme.bloodRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Earnings'),
                                const SizedBox(height: 8),
                                Text(
                                  'R ${earningsToday.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.bloodRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Deliveries'),
                                const SizedBox(height: 8),
                                Text(
                                  deliveredCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.bloodRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: SwitchListTile(
                            title: const Text('Notifications'),
                            value: notificationsEnabled,
                            activeColor: AppTheme.bloodRed,
                            onChanged: (v) =>
                                setState(() => notificationsEnabled = v),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time'),
                                const SizedBox(height: 8),
                                Builder(
                                  builder: (context) {
                                    final t = TimeOfDay.fromDateTime(
                                      DateTime.now(),
                                    ).format(context);
                                    return Text(
                                      t,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.bloodRed,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Orders', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filter == 'all',
                        onSelected: (v) {
                          if (v) setState(() => filter = 'all');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: filter == 'active',
                        onSelected: (v) {
                          if (v) setState(() => filter = 'active');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Delivered'),
                        selected: filter == 'delivered',
                        onSelected: (v) {
                          if (v) setState(() => filter = 'delivered');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ...filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      if (widget.onSelectOrder != null) {
                        widget.onSelectOrder!(order);
                        widget.goToDetails?.call();
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/orderDetails',
                          arguments: order,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _StatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(order.customerName),
                          const SizedBox(height: 4),
                          Text('Pickup: ${order.pickupAddress}'),
                          Text('Dropoff: ${order.deliveryAddress}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (widget.onSelectOrder != null) {
                                      widget.onSelectOrder!(order);
                                      widget.goToNavigate?.call();
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        '/navigate',
                                        arguments: order,
                                      );
                                    }
                                  },
                                  child: const Text('Navigate'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: TextButton(
                                  onPressed: () {
                                    if (widget.onSelectOrder != null) {
                                      widget.onSelectOrder!(order);
                                      widget.goToDetails?.call();
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        '/orderDetails',
                                        arguments: order,
                                      );
                                    }
                                  },
                                  child: const Text('Details'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('R ${order.payout.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'awaiting':
        bg = AppTheme.bloodRed.withOpacity(0.3);
        break;
      case 'in_progress':
        bg = AppTheme.bloodRed.withOpacity(0.6);
        break;
      case 'delivered':
        bg = Colors.green.withOpacity(0.3);
        break;
      default:
        bg = Colors.grey.withOpacity(0.3);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status),
    );
  }
}
