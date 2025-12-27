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
  String filter = 'nearby';
  bool notificationsEnabled = true;
  final orders = <Order>[];
  final _myOrders = <Order>[];
  bool loadingOrders = false;
  String? ordersError;
  LatLng? _driverCoord;
  final _distance = const Distance();
  static const double _ratePerKm = 5.0;
  Timer? _ordersTimer;
  Timer? _statsTimer;
  StreamSubscription<Position>? _posSub;
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> fetchOrders() async {
    _safeSetState(() {
      loadingOrders = true;
      ordersError = null;
    });
    try {
      final avail = await ApiClient.fetchAvailableOrders();
      final mine = await ApiClient.fetchMyOrders();
      await _ensureLocation();
      final nearbyAvail = _applyDistanceFilter(
        avail.where((o) {
          final s = o.status.toLowerCase();
          return s == 'awaiting' || s == 'confirmed';
        }).toList(),
      );
      final mineWithDist = _applyDistanceFilter(mine);
      _safeSetState(() {
        _myOrders
          ..clear()
          ..addAll(mineWithDist);
        final map = <String, Order>{};
        for (final o in _myOrders) {
          map[o.id] = o;
        }
        for (final o in nearbyAvail) {
          map.putIfAbsent(o.id, () => o);
        }
        final combined = map.values.toList();
        orders
          ..clear()
          ..addAll(combined);
        if (combined.isEmpty) {
          ordersError = 'No orders found';
        }
      });
    } catch (_) {
      _safeSetState(() {
        ordersError = 'Network error';
      });
    } finally {
      _safeSetState(() {
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
      await _pushLocationUpdate(pos);
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
    final nearby = withDist.where((o) => (o.distanceKm ?? 999) <= 8.0).toList();
    return nearby.isNotEmpty ? nearby : withDist;
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
    fetchDashboardStats();
    _startPolling();
    _startStatsPolling();
    _startPositionStream();
  }

  double get earningsToday => orders
      .where((o) => o.status == 'delivered')
      .fold(0.0, (sum, o) => sum + o.payout);

  int get deliveredCount => orders.where((o) => o.status == 'delivered').length;

  List<Order> get filteredOrders {
    switch (filter) {
      case 'active':
        final mineActive = _myOrders
            .where((o) => o.status != 'delivered')
            .toList();
        return mineActive.isNotEmpty
            ? mineActive
            : orders.where((o) => o.status != 'delivered').toList();
      case 'delivered':
        final mineDelivered = _myOrders
            .where((o) => o.status == 'delivered')
            .toList();
        return mineDelivered.isNotEmpty
            ? mineDelivered
            : orders.where((o) => o.status == 'delivered').toList();
      case 'nearby':
        final n = orders.where((o) => (o.distanceKm ?? 999) <= 8.0).toList();
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
        _safeSetState(() {
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

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchDashboardStats();
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
            _pushLocationUpdate(pos);
            _recomputeDistances();
          });
    } catch (_) {}
  }

  Future<bool> _openExternalDirections(Order order) async {
    final origin = _driverCoord;
    final destAddr = order.deliveryAddress;
    final destLat = order.dealerLat;
    final destLng = order.dealerLng;
    Uri? uri;
    if (origin != null) {
      final o = '${origin.latitude},${origin.longitude}';
      if ((destAddr ?? '').trim().isNotEmpty) {
        final d = Uri.encodeComponent(destAddr!);
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$o&destination=$d&travelmode=driving',
        );
      } else if (destLat != null && destLng != null) {
        final d = '${destLat},${destLng}';
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$o&destination=$d&travelmode=driving',
        );
      }
    } else if ((destAddr ?? '').trim().isNotEmpty) {
      final d = Uri.encodeComponent(destAddr!);
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$d');
    }
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _pushLocationUpdate(Position pos) async {
    if (currentUser?.driverId == null) return;
    try {
      await ApiClient.updateDriverLocation(pos.latitude, pos.longitude);
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
    _safeSetState(() {
      orders
        ..clear()
        ..addAll(updated);
    });
  }

  @override
  void dispose() {
    _ordersTimer?.cancel();
    _statsTimer?.cancel();
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
                        onPressed: () async {
                          final target = !available;
                          setState(() => available = target);
                          bool ok = false;
                          try {
                            ok = await ApiClient.updateDriverAvailability(
                              target,
                            );
                          } catch (_) {}
                          if (!ok) {
                            setState(() => available = !target);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update availability'),
                              ),
                            );
                          }
                        },
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
                    onTap: () async {
                      if (widget.onSelectOrder != null) {
                        widget.onSelectOrder!(order);
                        widget.goToDetails?.call();
                      } else {
                        await Navigator.pushNamed(
                          context,
                          '/orderDetails',
                          arguments: order,
                        );
                        await fetchOrders();
                        await fetchDashboardStats();
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final btnW = (w - 12) / 2;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: btnW,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
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
                                                  title: const Text(
                                                    'Accept Order',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Accept',
                                                      ),
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Accepting order...'),
                                          ),
                                        );
                                        bool okAccept = false;
                                        try {
                                          okAccept =
                                              await ApiClient.acceptOrder(
                                                order.id,
                                                proposedFee: pay,
                                                pickupTime: DateTime.now(),
                                              );
                                        } catch (_) {}
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentSnackBar();
                                        if (!okAccept) {
                                          final err =
                                              ApiClient.lastError ??
                                              'Failed to accept order';
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(err)),
                                          );
                                          return;
                                        }
                                        // Start navigation immediately without waiting for assignment polling
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Starting navigation...',
                                            ),
                                          ),
                                        );
                                        if (widget.onSelectOrder != null) {
                                          widget.onSelectOrder!(order);
                                          widget.goToNavigate?.call();
                                        } else {
                                          final usedExternal =
                                              DriverSession.mapboxToken.isEmpty
                                              ? await _openExternalDirections(
                                                  order,
                                                )
                                              : false;
                                          if (!usedExternal) {
                                            await Navigator.pushNamed(
                                              context,
                                              '/navigate',
                                              arguments: {
                                                'order': order,
                                                'autoStart': true,
                                              },
                                            );
                                            await fetchOrders();
                                            await fetchDashboardStats();
                                          } else {
                                            await Future.delayed(
                                              const Duration(seconds: 2),
                                            );
                                            await fetchOrders();
                                            await fetchDashboardStats();
                                          }
                                        }
                                        try {
                                          final okStatus =
                                              await ApiClient.updateOrderStatus(
                                                order.id,
                                                'picked_up',
                                                action: 'update_status',
                                                extra: {
                                                  'driver_pickup_time':
                                                      ApiClient.nowTs(),
                                                  'driver_assigned_at':
                                                      ApiClient.nowTs(),
                                                  if (pay != null) 'fee': pay,
                                                  if (pay != null)
                                                    'delivery_fee': pay,
                                                },
                                              );
                                          if (!okStatus) {
                                            final err =
                                                ApiClient.lastError ??
                                                'Failed to update status';
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(content: Text(err)),
                                            );
                                          }
                                        } catch (_) {}
                                        try {
                                          await fetchOrders();
                                          await fetchDashboardStats();
                                        } catch (_) {}
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text('Accept'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: btnW,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
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
                                          await fetchOrders();
                                          await fetchDashboardStats();
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
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.cancel_outlined, size: 18),
                                          SizedBox(width: 6),
                                          Text('Reject'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Builder(
                                    builder: (_) {
                                      final d = order.distanceKm;
                                      if (d == null)
                                        return const SizedBox.shrink();
                                      final pay = d * _ratePerKm;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Pay: R ' + pay.toStringAsFixed(2),
                                        ),
                                      );
                                    },
                                  ),
                                  if (order.distanceKm != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${order.distanceKm!.toStringAsFixed(1)} km',
                                      ),
                                    ),
                                ],
                              );
                            },
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
