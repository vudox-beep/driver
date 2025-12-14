import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

class NavigationScreen extends StatelessWidget {
  final Order? order;
  const NavigationScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.bloodRed, width: 1.2),
              ),
              child: const Center(
                child: Text(
                  'Map Placeholder',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${o != null ? o.pickupAddress : '-'}'),
                    Text('To:   ${o != null ? o.deliveryAddress : '-'}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (o != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Starting navigation...'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Start'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
