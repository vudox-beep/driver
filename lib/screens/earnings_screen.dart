import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final history = <DeliveryHistory>[
    const DeliveryHistory(
      id: 'ORD-1003',
      date: '2025-12-12',
      summary: 'Grocery dropoff',
      amount: 9.75,
    ),
    const DeliveryHistory(
      id: 'ORD-1004',
      date: '2025-12-13',
      summary: 'Pharmacy pickup',
      amount: 14.20,
    ),
    const DeliveryHistory(
      id: 'ORD-1005',
      date: '2025-12-14',
      summary: 'Food delivery',
      amount: 11.10,
    ),
  ];
  bool loading = false;
  String? error;

  double get total => history.fold(0.0, (sum, h) => sum + h.amount);

  Future<void> fetchEarnings() async {
    if (currentUser?.driverId == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final uri = Uri.parse(ApiEndpoints.earnings);
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'driver_id': currentUser!.driverId}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == true) {
          final list = (data['data'] is Map && data['data']['history'] is List)
              ? List<Map<String, dynamic>>.from(data['data']['history'])
              : <Map<String, dynamic>>[];
          final parsed = list
              .map(
                (e) => DeliveryHistory(
                  id: (e['id'] ?? e['order_id'] ?? '').toString(),
                  date: (e['date'] ?? e['created_at'] ?? '').toString(),
                  summary: (e['summary'] ?? e['description'] ?? '').toString(),
                  amount:
                      double.tryParse(
                        (e['amount'] ?? e['payout'] ?? '0').toString(),
                      ) ??
                      0.0,
                ),
              )
              .toList();
          setState(() {
            if (parsed.isNotEmpty) {
              history
                ..clear()
                ..addAll(parsed);
            }
          });
        } else {
          setState(() {
            error = (data is Map && data['message'] is String)
                ? data['message']
                : 'Failed to load earnings';
          });
        }
      } else {
        setState(() {
          error = res.body.isNotEmpty ? res.body : 'Failed to load earnings';
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
      appBar: AppBar(title: const Text('Earnings & History')),
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
                    const Text('Total'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
