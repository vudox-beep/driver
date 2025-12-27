import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order? order;
  const OrderDetailsScreen({super.key, this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? details;
  bool loading = false;
  String? error;
  double? distanceKm;
  double? pay;
  static const double _ratePerKm = 5.0;
  bool navigationStarted = false;

  String _clean(String? v) {
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

  Future<void> fetchDetails() async {
    if (widget.order == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await ApiClient.fetchOrderDetailsFromOrdersPage(
        widget.order!.id,
      );
      if (d != null) {
        setState(() => details = d);
        await _computePriceFor(d);
      } else {
        setState(() => error = 'Failed to load order');
      }
    } catch (_) {
      setState(() => error = 'Network error');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<Map<String, double>?> _geocode(String address) async {
    if (address.trim().isEmpty) return null;
    if (DriverSession.mapboxToken.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?limit=1&access_token=${DriverSession.mapboxToken}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map &&
              data['features'] is List &&
              (data['features'] as List).isNotEmpty) {
            final first = (data['features'] as List).first as Map;
            final center = first['center'];
            if (center is List && center.length >= 2) {
              final lon = (center[0] as num).toDouble();
              final lat = (center[1] as num).toDouble();
              return {'lat': lat, 'lon': lon};
            }
          }
        }
      } catch (_) {}
    }
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
          .replace(
            queryParameters: {'format': 'json', 'limit': '1', 'q': address},
          );
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'driver-app/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final lat = double.tryParse((first['lat'] ?? '').toString());
          final lon = double.tryParse((first['lon'] ?? '').toString());
          if (lat != null && lon != null) {
            return {'lat': lat, 'lon': lon};
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _computePriceFor(Order o) async {
    try {
      final from = await _geocode(_clean(o.pickupAddress));
      final to = await _geocode(_clean(o.deliveryAddress));
      if (from == null || to == null) return;
      if (DriverSession.mapboxToken.isNotEmpty) {
        final uri = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${to!['lon']},${to['lat']};${from!['lon']},${from['lat']}?overview=false&geometries=geojson&access_token=${DriverSession.mapboxToken}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map &&
              data['routes'] is List &&
              (data['routes'] as List).isNotEmpty) {
            final route = (data['routes'] as List).first as Map;
            final distMeters = (route['distance'] as num?)?.toDouble();
            if (distMeters != null) {
              final km = distMeters / 1000.0;
              setState(() {
                distanceKm = km;
                pay = km * _ratePerKm;
              });
              return;
            }
          }
        }
      }
      final d = Distance();
      final km = d.as(
        LengthUnit.Kilometer,
        LatLng(from['lat']!, from['lon']!),
        LatLng(to['lat']!, to['lon']!),
      );
      setState(() {
        distanceKm = km;
        pay = km * _ratePerKm;
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    fetchDetails();
    if (widget.order != null) {
      _computePriceFor(widget.order!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = details ?? widget.order;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _clean(error!),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
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
                          ? 'Customer: ${_clean(o.customerName)}'
                          : 'Select an order from Home',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o != null
                          ? 'Pickup: ${_clean(o.pickupAddress)}'
                          : 'Pickup: -',
                    ),
                    Text(
                      o != null
                          ? 'Dropoff: ${_clean(o.deliveryAddress)}'
                          : 'Dropoff: -',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o != null ? 'Status: ${_clean(o.status)}' : 'Status: -',
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        if (distanceKm == null || pay == null)
                          return const SizedBox.shrink();
                        return Text(
                          'Pay: R ' +
                              pay!.toStringAsFixed(2) +
                              ' • ' +
                              distanceKm!.toStringAsFixed(1) +
                              ' km',
                          style: const TextStyle(color: AppTheme.bloodRed),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final btnW = w >= 560 ? (w - 36) / 4 : (w - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: btnW,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: o == null
                            ? null
                            : () async {
                                final res = await Navigator.pushNamed(
                                  context,
                                  '/navigate',
                                  arguments: {'order': o, 'autoStart': true},
                                );
                                if (!mounted) return;
                                setState(() {
                                  navigationStarted =
                                      (res is Map && (res['started'] == true));
                                });
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.navigation, size: 18),
                            SizedBox(width: 6),
                            Text('Navigate'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: btnW,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: (o == null || !navigationStarted)
                            ? null
                            : () async {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cancelling delivery...'),
                                  ),
                                );
                                final ok = await ApiClient.updateOrderStatus(
                                  o!.id,
                                  'awaiting',
                                  action: 'update_status',
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Order returned to awaiting'
                                          : 'Failed to cancel',
                                    ),
                                  ),
                                );
                                if (ok && mounted) Navigator.pop(context);
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cancel_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Cancel'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: btnW,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: (o == null || !navigationStarted)
                            ? null
                            : () async {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marking delivered...'),
                                  ),
                                );
                                final ok = await ApiClient.updateOrderStatus(
                                  o!.id,
                                  'delivered',
                                  action: 'update_status',
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Marked as delivered'
                                          : 'Failed to update status',
                                    ),
                                  ),
                                );
                                if (ok && mounted) Navigator.pop(context);
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 6),
                            Text('Delivered'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: btnW,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: (o == null || !navigationStarted)
                            ? null
                            : () async {
                                String phone = (o!.customerPhone ?? '').trim();
                                if (phone.isEmpty) {
                                  final fetched =
                                      await ApiClient.fetchOrderDetailsFromOrdersPage(
                                        o.id,
                                      );
                                  if (fetched?.customerPhone?.isNotEmpty ==
                                      true) {
                                    phone = fetched!.customerPhone!;
                                  }
                                }
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No customer phone'),
                                    ),
                                  );
                                  return;
                                }
                                final uri = Uri.parse('tel:' + phone);
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Unable to open dialer'),
                                    ),
                                  );
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.phone_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Call'),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
