import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../theme.dart';
import '../services/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final orders = <Order>[];
  bool loadingOrders = false;
  String? ordersError;
  LatLng? _driverCoord;
  final _distance = const Distance();
  static const double _ratePerKm = 5.0;
  Timer? _ordersTimer;
  StreamSubscription<Position>? _posSub;

  Future<void> fetchOrders() async {
    setState(() {
      loadingOrders = true;
      ordersError = null;
    });
    try {
      final parsed = await ApiClient.fetchAvailableOrders();
      await _ensureLocation();
      setState(() {
        if (parsed.isNotEmpty) {
          orders
            ..clear()
            ..addAll(_applyDistanceFilter(parsed));
        } else {
          ordersError = 'Failed to load orders';
        }
      });
    } catch (_) {
      setState(() {
        ordersError = 'Network error';
      });
    } finally {
      setState(() {
        loadingOrders = false;
      });
    }
  }

  Future<void> _ensureLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _driverCoord = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  List<Order> _applyDistanceFilter(List<Order> list) {
    if (_driverCoord == null) return list;
    final withDist = list.map((o) {
      if (o.dealerLat != null && o.dealerLng != null) {
        final d = _distance.as(
          LengthUnit.Kilometer,
          _driverCoord!,
          LatLng(o.dealerLat!, o.dealerLng!),
        );
        return Order(
          id: o.id,
          customerName: o.customerName,
          pickupAddress: o.pickupAddress,
          deliveryAddress: o.deliveryAddress,
          status: o.status,
          payout: o.payout,
          dealerLat: o.dealerLat,
          dealerLng: o.dealerLng,
          distanceKm: d,
        );
      }
      return o;
    }).toList();
    final nearby = withDist.where((o) => (o.distanceKm ?? 999) <= 7.0).toList();
    return nearby.isNotEmpty ? nearby : withDist;
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
    fetchDashboardStats();
    _startPolling();
    _startPositionStream();
  }

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
      case 'nearby':
        final n = orders.where((o) => (o.distanceKm ?? 999) <= 7.0).toList();
        return n.isNotEmpty ? n : orders;
      default:
        return orders;
    }
  }

  double? dashboardTotal;
  int? dashboardDelivered;
  int? dashboardActive;

  Future<void> fetchDashboardStats() async {
    if (currentUser?.driverId == null) return;
    try {
      final d = await ApiClient.fetchDashboard(currentUser!.driverId!);
      if (d != null) {
        setState(() {
          dashboardTotal = (d['total_earnings'] as num?)?.toDouble();
          dashboardDelivered = (d['deliveries_count'] as num?)?.toInt();
          dashboardActive = (d['active_orders'] as num?)?.toInt();
        });
      }
    } catch (_) {}
  }

  void _startPolling() {
    _ordersTimer?.cancel();
    _ordersTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchOrders();
    });
  }

  void _startPositionStream() {
    try {
      _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 25,
            ),
          ).listen((pos) {
            _driverCoord = LatLng(pos.latitude, pos.longitude);
            _recomputeDistances();
          });
    } catch (_) {}
  }

  void _recomputeDistances() {
    if (_driverCoord == null || orders.isEmpty) return;
    final updated = orders.map((o) {
      if (o.dealerLat != null && o.dealerLng != null) {
        final d = _distance.as(
          LengthUnit.Kilometer,
          _driverCoord!,
          LatLng(o.dealerLat!, o.dealerLng!),
        );
        return Order(
          id: o.id,
          customerName: o.customerName,
          pickupAddress: o.pickupAddress,
          deliveryAddress: o.deliveryAddress,
          status: o.status,
          payout: o.payout,
          dealerLat: o.dealerLat,
          dealerLng: o.dealerLng,
          distanceKm: d,
        );
      }
      return o;
    }).toList();
    setState(() {
      orders
        ..clear()
        ..addAll(updated);
    });
  }

  @override
  void dispose() {
    _ordersTimer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tastebud'),
        actions: [
          IconButton(
            tooltip: 'Open Orders Page',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final url = Uri.parse(ApiEndpoints.ordersPage);
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tastebud', style: TextStyle(fontSize: 20)),
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
            if (loadingOrders)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              ),
            if (ordersError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  ordersError!,
                  style: const TextStyle(color: Colors.redAccent),
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
                                  'R ${(dashboardTotal ?? earningsToday).toStringAsFixed(2)}',
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
                                  (dashboardDelivered ?? deliveredCount)
                                      .toString(),
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
                        label: const Text('Nearby'),
                        selected: filter == 'nearby',
                        onSelected: (v) {
                          if (v) setState(() => filter = 'nearby');
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
                                order.id.replaceAll(RegExp(r"<[^>]*>"), ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _StatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.customerName.replaceAll(
                              RegExp(r"<[^>]*>"),
                              '',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pickup: ${order.pickupAddress.replaceAll(RegExp(r"<[^>]*>"), '')}',
                          ),
                          Text(
                            'Dropoff: ${order.deliveryAddress.replaceAll(RegExp(r"<[^>]*>"), '')}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final dist = order.distanceKm;
                                    final pay = dist != null
                                        ? dist * _ratePerKm
                                        : null;
                                    final okConfirm =
                                        await showDialog<bool>(
                                          context: context,
                                          builder: (_) {
                                            return AlertDialog(
                                              title: const Text('Accept Order'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Customer: ' +
                                                        order.customerName
                                                            .replaceAll(
                                                              RegExp(
                                                                r"<[^>]*>",
                                                              ),
                                                              '',
                                                            ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (dist != null)
                                                    Text(
                                                      'Distance: ' +
                                                          dist.toStringAsFixed(
                                                            1,
                                                          ) +
                                                          ' km',
                                                    ),
                                                  if (pay != null)
                                                    Text(
                                                      'Pay: R ' +
                                                          pay.toStringAsFixed(
                                                            2,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Accept'),
                                                ),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;
                                    if (!okConfirm) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Accepting order...'),
                                      ),
                                    );
                                    final ok = await ApiClient.acceptOrder(
                                      order.id,
                                    );
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    if (ok) {
                                      if (widget.onSelectOrder != null) {
                                        widget.onSelectOrder!(order);
                                        widget.goToNavigate?.call();
                                      } else {
                                        Navigator.pushNamed(
                                          context,
                                          '/navigate',
                                          arguments: {
                                            'order': order,
                                            'autoStart': true,
                                          },
                                        );
                                      }
                                    } else {
                                      final noAuth =
                                          (DriverSession.authToken ?? '')
                                              .isEmpty &&
                                          (currentUser?.driverId == null);
                                      final msg = noAuth
                                          ? 'Please log in as driver to accept orders'
                                          : (ApiClient.lastError?.isNotEmpty ==
                                                    true
                                                ? ApiClient.lastError!
                                                : 'Failed to accept order');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(msg)),
                                      );
                                    }
                                  },
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: TextButton(
                                  onPressed: () async {
                                    final ok = await ApiClient.rejectOrder(
                                      order.id,
                                    );
                                    if (ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Order rejected'),
                                        ),
                                      );
                                      fetchOrders();
                                    } else {
                                      final noAuth =
                                          (DriverSession.authToken ?? '')
                                              .isEmpty &&
                                          (currentUser?.driverId == null);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            noAuth
                                                ? 'Please log in as driver to reject orders'
                                                : 'Failed to reject order',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Builder(
                                builder: (_) {
                                  final d = order.distanceKm;
                                  if (d == null) return const SizedBox.shrink();
                                  final pay = d * _ratePerKm;
                                  return Text(
                                    'Pay: R ' + pay.toStringAsFixed(2),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              if (order.distanceKm != null)
                                Text(
                                  '${order.distanceKm!.toStringAsFixed(1)} km',
                                ),
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
