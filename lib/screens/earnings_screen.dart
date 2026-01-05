import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import '../services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final history = <DeliveryHistory>[]; // delivered earnings history
  final accepted = <DeliveryHistory>[]; // accepted offers
  bool loading = false;
  String? error;
  double total = 0.0; // delivered total from API
  final updating = <String>{};

  String _s(String? v) {
    final s = (v ?? '').toString();
    final a = s.replaceAll(RegExp(r"<[^>]*>"), '');
    final b = a
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');
    final c = b.replaceAll(RegExp(r"\s+"), ' ').trim();
    return c;
  }

  Future<void> fetchEarnings() async {
    if (currentUser?.driverId == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await ApiClient.fetchDriverAssignmentsAndStats(
        currentUser!.driverId!,
      );
      if (r != null) {
        setState(() {
          total = (r['total'] as double?) ?? 0.0;
          final acc = (r['accepted'] as List<DeliveryHistory>?);
          final del = (r['delivered'] as List<DeliveryHistory>?);
          accepted
            ..clear()
            ..addAll(acc ?? const []);
          history
            ..clear()
            ..addAll(del ?? const []);
        });
      } else {
        setState(() {
          error = 'Failed to load earnings';
        });
      }
    } catch (_) {
      setState(() {
        error = 'Network error';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Column(
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Earnings'),
                    Text(
                      'R ${total.toStringAsFixed(2)}',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (accepted.isNotEmpty) ...[
                  const Text(
                    'Accepted Offers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...accepted.map(
                    (item) => Card(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (item.customerName ?? '').isNotEmpty
                                            ? item.customerName!
                                            : item.id,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if ((item.address ?? '').isNotEmpty)
                                        Text(item.address!),
                                      const SizedBox(height: 4),
                                      Text(item.date),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('R ${item.amount.toStringAsFixed(2)}'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 120,
                                      child: ElevatedButton(
                                        onPressed: updating.contains(item.id)
                                            ? null
                                            : () async {
                                                setState(() {
                                                  updating.add(item.id);
                                                });
                                                final ok =
                                                    await ApiClient.markDelivered(
                                                  item.id,
                                                );
                                                if (ok) {
                                                  await fetchEarnings();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Earnings updated',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed: ${ApiClient.lastError ?? 'update failed'}',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                setState(() {
                                                  updating.remove(item.id);
                                                });
                                              },
                                        child: const Text('Deliver'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Earnings History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty) const Text('No delivered orders yet'),
                ...history.map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
