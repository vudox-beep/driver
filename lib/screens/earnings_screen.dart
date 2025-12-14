import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = <DeliveryHistory>[
      const DeliveryHistory(id: 'ORD-1003', date: '2025-12-12', summary: 'Grocery dropoff', amount: 9.75),
      const DeliveryHistory(id: 'ORD-1004', date: '2025-12-13', summary: 'Pharmacy pickup', amount: 14.20),
      const DeliveryHistory(id: 'ORD-1005', date: '2025-12-14', summary: 'Food delivery', amount: 11.10),
    ];
    final total = history.fold(0.0, (sum, h) => sum + h.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total'),
                    Text(
                      'R ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.bloodRed),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item.summary),
                            const SizedBox(height: 4),
                            Text(item.date),
                          ],
                        ),
                        Text('R ${item.amount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
