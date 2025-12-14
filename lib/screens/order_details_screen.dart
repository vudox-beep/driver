import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order? order;
  const OrderDetailsScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o != null ? o.id : 'No order selected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o != null
                          ? 'Customer: ${o.customerName}'
                          : 'Select an order from Home',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o != null ? 'Pickup: ${o.pickupAddress}' : 'Pickup: -',
                    ),
                    Text(
                      o != null
                          ? 'Dropoff: ${o.deliveryAddress}'
                          : 'Dropoff: -',
                    ),
                    const SizedBox(height: 8),
                    Text(o != null ? 'Status: ${o.status}' : 'Status: -'),
                    const SizedBox(height: 8),
                    Text(
                      'Payout: R ${o != null ? o.payout.toStringAsFixed(2) : '0.00'}',
                      style: const TextStyle(color: AppTheme.bloodRed),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: o == null
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            '/navigate',
                            arguments: o,
                          ),
                    child: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: o == null
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Marked as delivered'),
                              ),
                            );
                          },
                    child: const Text('Mark Delivered'),
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
