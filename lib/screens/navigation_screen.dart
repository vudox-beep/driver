import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';

class _PointClick implements mapbox.OnPointAnnotationClickListener {
  final void Function(mapbox.PointAnnotation) onClick;
  _PointClick(this.onClick);
  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    onClick(annotation);
  }
}

class NavigationScreen extends StatefulWidget {
  final Order? order;
  final bool autoStart;
  const NavigationScreen({super.key, this.order, this.autoStart = false});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  String? mapUrl;
  bool loading = false;
  String? error;
  LatLng? fromCoord;
  LatLng? toCoord;
  LatLng? centerCoord;
  final mapController = fmap.MapController();
  mapbox.MapboxMap? _mapbox;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolylineAnnotationManager? _polylineManager;
  _PointClick? _tapListener;
  List<LatLng> routePoints = const [];
  double? routeDistanceKm;
  double? routeFare;
  static const double _ratePerKm = 5.0;
  LatLng? userCoord;
  String? userAddress;
  StreamSubscription<Position>? _posSub;
  bool navToPickup = false;
  final Distance _distCalc = const Distance();

  void _onPointAnnotationTap(mapbox.PointAnnotation ann) {
    final o = widget.order;
    final pos = ann.geometry.coordinates as mapbox.Position;
    final isFrom =
        fromCoord != null &&
        (pos.lng - fromCoord!.longitude).abs() < 1e-6 &&
        (pos.lat - fromCoord!.latitude).abs() < 1e-6;
    final isTo =
        toCoord != null &&
        (pos.lng - toCoord!.longitude).abs() < 1e-6 &&
        (pos.lat - toCoord!.latitude).abs() < 1e-6;
    final title = isFrom ? 'Pickup' : (isTo ? 'Dropoff' : 'Location');
    final address = isFrom
        ? (o != null ? _clean(o.pickupAddress) : '')
        : (isTo ? (o != null ? _clean(o.deliveryAddress) : '') : '');
    final cust = o != null ? _clean(o.customerName) : '';
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cust.isNotEmpty) Text('Customer: ' + cust),
              if (address.isNotEmpty) Text('Address: ' + address),
              if (routeDistanceKm != null)
                Text(
                  'Distance: ' + routeDistanceKm!.toStringAsFixed(1) + ' km',
                ),
              if (routeFare != null)
                Text('Cost: R ' + routeFare!.toStringAsFixed(2)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

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

  @override
  void initState() {
    super.initState();
    _ensureLocation();
    _startPositionStream();
    _load();
  }

  Future<void> _load() async {
    final o = widget.order;
    if (o == null) {
      setState(() {
        centerCoord = const LatLng(-26.2041, 28.0473);
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final from = await _geocode(_clean(o.pickupAddress));
      final to = await _geocode(_clean(o.deliveryAddress));
      if (from == null && to == null) {
        setState(() {
          error = 'Unable to locate order addresses';
          centerCoord = const LatLng(-26.2041, 28.0473);
        });
        return;
      }
      setState(() {
        if (from != null) {
          fromCoord = LatLng(from['lat']!, from['lon']!);
        }
        if (to != null) {
          toCoord = LatLng(to['lat']!, to['lon']!);
        }
      });
      if (DriverSession.mapboxToken.isNotEmpty && _mapbox != null) {
        await _syncMapboxAnnotations();
      }
      if (widget.autoStart) {
        await _startNavigation();
      }
    } catch (_) {
      setState(() {
        error = 'Map loading error';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _startNavigation() async {
    final o = widget.order;
    if (o == null) return;
    LatLng? from = fromCoord;
    LatLng? to = toCoord;
    if (from == null || to == null) {
      try {
        final f = await _geocode(_clean(o.pickupAddress));
        final t = await _geocode(_clean(o.deliveryAddress));
        if (f != null && t != null) {
          from = LatLng(f['lat']!, f['lon']!);
          to = LatLng(t['lat']!, t['lon']!);
        } else {
          if (from == null && f != null) {
            from = LatLng(f['lat']!, f['lon']!);
          }
          if (to == null && t != null) {
            to = LatLng(t['lat']!, t['lon']!);
          }
        }
      } catch (_) {}
    }
    if ((from == null || to == null) &&
        o.dealerLat != null &&
        o.dealerLng != null) {
      final store = LatLng(o.dealerLat!, o.dealerLng!);
      if (from == null) from = store;
      if (to == null) to = store;
    }
    if (from == null && to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start navigation')),
      );
      return;
    }
    if (DriverSession.mapboxToken.isNotEmpty) {
      setState(() {
        fromCoord = from;
        toCoord = to;
      });
      if (userCoord != null) {
        navToPickup = from != null;
        await _recalcRouteFromUser();
      } else {
        if (from != null && to != null) {
          final ok = await _fetchRoute(from, to);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to get directions')),
            );
          }
        } else {
          await _syncMapboxAnnotations();
        }
      }
      return;
    }
    setState(() {
      fromCoord = from;
      toCoord = to;
    });
    if (from != null && to != null) {
      await _fetchRoute(from, to);
    } else {
      await _syncMapboxAnnotations();
    }
  }

  List<LatLng> _decodePolyline6(String encoded) {
    int index = 0;
    int lat = 0;
    int lng = 0;
    final coords = <LatLng>[];
    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      final latD = lat / 1e6;
      final lngD = lng / 1e6;
      coords.add(LatLng(latD, lngD));
    }
    return coords;
  }

  Future<bool> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?geometries=polyline6&overview=full&access_token=${DriverSession.mapboxToken}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List).first as Map;
          final geometry = (route['geometry'] ?? '').toString();
          final pts = _decodePolyline6(geometry);
          if (pts.isNotEmpty) {
            setState(() {
              routePoints = pts;
              final distMeters = (route['distance'] as num?)?.toDouble();
              if (distMeters != null) {
                routeDistanceKm = distMeters / 1000.0;
                routeFare = routeDistanceKm! * _ratePerKm;
              } else {
                routeDistanceKm = null;
                routeFare = null;
              }
            });
            if (_mapbox != null) {
              await _syncMapboxAnnotations();
              await _fitCameraToTargets();
            }
            return true;
          }
        }
      }
    } catch (_) {}
    // Fallback: draw straight line between points and compute distance locally
    try {
      final km = _distCalc.as(LengthUnit.Kilometer, from, to);
      setState(() {
        routePoints = [from, to];
        routeDistanceKm = km;
        routeFare = km * _ratePerKm;
      });
      await _syncMapboxAnnotations();
      await _fitCameraToTargets();
      return true;
    } catch (_) {}
    return false;
  }

  Future<void> _recalcRouteFromUser() async {
    if (userCoord == null) return;
    LatLng? target;
    if (navToPickup && fromCoord != null) {
      target = fromCoord;
    } else if (toCoord != null) {
      target = toCoord;
    }
    if (target == null) return;
    final reached = _distCalc.as(LengthUnit.Meter, userCoord!, target) < 40;
    if (reached && navToPickup) {
      navToPickup = false;
      target = toCoord;
    }
    if (target != null) {
      await _fetchRoute(userCoord!, target);
    }
  }

  Future<void> _fitCameraToTargets() async {
    final pts = <LatLng>[];
    if (routePoints.isNotEmpty) {
      pts.addAll(routePoints);
    } else {
      if (userCoord != null) pts.add(userCoord!);
      if (fromCoord != null) pts.add(fromCoord!);
      if (toCoord != null) pts.add(toCoord!);
    }
    if (pts.isEmpty) return;
    double minLat = pts.first.latitude,
        maxLat = pts.first.latitude,
        minLng = pts.first.longitude,
        maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();
    final span = spanLat > spanLng ? spanLat : spanLng;
    double zoom;
    if (span < 0.01) {
      zoom = 15;
    } else if (span < 0.05) {
      zoom = 13;
    } else if (span < 0.2) {
      zoom = 11;
    } else if (span < 1.0) {
      zoom = 9;
    } else {
      zoom = 7;
    }
    if (_mapbox != null) {
      await _mapbox!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(center.longitude, center.latitude),
          ),
          zoom: zoom,
        ),
      );
    } else {
      mapController.move(center, zoom);
    }
  }

  Future<void> _syncMapboxAnnotations() async {
    if (_mapbox == null) return;
    _pointManager ??= await _mapbox!.annotations.createPointAnnotationManager();
    _polylineManager ??= await _mapbox!.annotations
        .createPolylineAnnotationManager();
    await _pointManager!.deleteAll();
    await _polylineManager!.deleteAll();
    final o = widget.order;
    if (fromCoord != null) {
      await _pointManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              fromCoord!.longitude,
              fromCoord!.latitude,
            ),
          ),
          textField: o != null
              ? 'Pickup: ' + _clean(o.pickupAddress)
              : 'Pickup',
        ),
      );
    }
    if (toCoord != null) {
      await _pointManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(toCoord!.longitude, toCoord!.latitude),
          ),
          textField: o != null
              ? 'Dropoff: ' + _clean(o.deliveryAddress)
              : 'Dropoff',
        ),
      );
    }
    if (userCoord != null) {
      await _pointManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              userCoord!.longitude,
              userCoord!.latitude,
            ),
          ),
          textField: (userAddress ?? 'You'),
        ),
      );
    }
    _tapListener ??= _PointClick(_onPointAnnotationTap);
    _pointManager!.addOnPointAnnotationClickListener(_tapListener!);
    if (routePoints.isNotEmpty) {
      final coords = routePoints
          .map((e) => mapbox.Position(e.longitude, e.latitude))
          .toList(growable: false);
      await _polylineManager!.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: coords),
          lineWidth: 6.0,
          lineColor: Colors.blue.value,
          lineOpacity: 0.9,
        ),
      );
    }
    await _fitCameraToTargets();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          userCoord = LatLng(pos.latitude, pos.longitude);
          centerCoord = userCoord;
        });
        final addr = await _reverseGeocode(userCoord!);
        if (addr != null && addr.isNotEmpty) {
          setState(() {
            userAddress = addr;
          });
        }
        if (_mapbox != null) {
          await _syncMapboxAnnotations();
        }
      }
    } catch (_) {}
  }

  void _startPositionStream() {
    try {
      _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) async {
            setState(() {
              userCoord = LatLng(pos.latitude, pos.longitude);
              centerCoord = userCoord;
            });
            if (_mapbox != null) {
              await _mapbox!.setCamera(
                mapbox.CameraOptions(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(
                      userCoord!.longitude,
                      userCoord!.latitude,
                    ),
                  ),
                  zoom: 13,
                ),
              );
              await _syncMapboxAnnotations();
              if (_mapbox == null) {
                mapController.move(userCoord!, 13);
              }
              await _recalcRouteFromUser();
            }
          });
    } catch (_) {}
  }

  Future<String?> _reverseGeocode(LatLng p) async {
    if (DriverSession.mapboxToken.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${p.longitude},${p.latitude}.json?types=address&limit=1&access_token=${DriverSession.mapboxToken}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map &&
              data['features'] is List &&
              (data['features'] as List).isNotEmpty) {
            final first = (data['features'] as List).first as Map;
            final place = (first['place_name'] ?? '').toString();
            if (place.isNotEmpty) return place;
          }
        }
      } catch (_) {}
    }
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${p.latitude}&lon=${p.longitude}',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'driver-app/1.0'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final d = (data['display_name'] ?? '').toString();
          if (d.isNotEmpty) return d;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, double>?> _geocode(String address) async {
    if (address.trim().isEmpty) return null;

    if (DriverSession.mapboxToken.isNotEmpty) {
      try {
        final base =
            'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json';
        final qp = <String, String>{
          'limit': '1',
          'types': 'poi,address,place',
          'access_token': DriverSession.mapboxToken,
        };
        if (userCoord != null) {
          qp['proximity'] = '${userCoord!.longitude},${userCoord!.latitude}';
        }
        final uri = Uri.parse(base).replace(queryParameters: qp);
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

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  border: Border.all(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.bloodRed, width: 1.2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DriverSession.mapboxToken.isNotEmpty
                        ? mapbox.MapWidget(
                            cameraOptions: mapbox.CameraOptions(
                              center: mapbox.Point(
                                coordinates: mapbox.Position(
                                  (centerCoord ??
                                          fromCoord ??
                                          toCoord ??
                                          const LatLng(-26.2041, 28.0473))
                                      .longitude,
                                  (centerCoord ??
                                          fromCoord ??
                                          toCoord ??
                                          const LatLng(-26.2041, 28.0473))
                                      .latitude,
                                ),
                              ),
                              zoom: 13,
                            ),
                            onMapCreated: (m) async {
                              _mapbox = m;
                              try {
                                await _mapbox!.location.updateSettings(
                                  mapbox.LocationComponentSettings(
                                    enabled: true,
                                  ),
                                );
                              } catch (_) {}
                              await _syncMapboxAnnotations();
                              if (widget.autoStart) {
                                await _startNavigation();
                              }
                            },
                          )
                        : fmap.FlutterMap(
                            mapController: mapController,
                            options: fmap.MapOptions(
                              initialCenter:
                                  centerCoord ??
                                  fromCoord ??
                                  toCoord ??
                                  const LatLng(-26.2041, 28.0473),
                              initialZoom: 13,
                            ),
                            children: [
                              fmap.TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              if (fromCoord != null || toCoord != null)
                                fmap.MarkerLayer(
                                  markers: [
                                    if (fromCoord != null)
                                      fmap.Marker(
                                        point: fromCoord!,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.lightBlueAccent,
                                          size: 36,
                                        ),
                                      ),
                                    if (toCoord != null)
                                      fmap.Marker(
                                        point: toCoord!,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.flag,
                                          color: Colors.redAccent,
                                          size: 32,
                                        ),
                                      ),
                                    if (userCoord != null)
                                      fmap.Marker(
                                        point: userCoord!,
                                        width: 36,
                                        height: 36,
                                        child: const Icon(
                                          Icons.person_pin_circle,
                                          color: Colors.greenAccent,
                                          size: 32,
                                        ),
                                      ),
                                  ],
                                ),
                              if (routePoints.isNotEmpty)
                                fmap.PolylineLayer(
                                  polylines: [
                                    fmap.Polyline(
                                      points: routePoints,
                                      color: Colors.blue,
                                      strokeWidth: 6,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                  if (loading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                ],
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
                    if (o != null) Text('Customer: ' + _clean(o.customerName)),
                    Text('From: ${o != null ? _clean(o.pickupAddress) : '-'}'),
                    Text(
                      'To:   ${o != null ? _clean(o.deliveryAddress) : '-'}',
                    ),
                    Builder(
                      builder: (_) {
                        if (fromCoord == null && toCoord == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fromCoord != null)
                              Text(
                                'Pickup coords: ${fromCoord!.latitude.toStringAsFixed(5)}, ${fromCoord!.longitude.toStringAsFixed(5)}',
                              ),
                            if (toCoord != null)
                              Text(
                                'Dropoff coords: ${toCoord!.latitude.toStringAsFixed(5)}, ${toCoord!.longitude.toStringAsFixed(5)}',
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (_) {
                        final dist = routeDistanceKm ?? o?.distanceKm;
                        if (dist == null) return const SizedBox.shrink();
                        return Text(
                          'Distance: ' + dist.toStringAsFixed(1) + ' km',
                        );
                      },
                    ),
                    Builder(
                      builder: (_) {
                        if (userCoord == null) return const SizedBox.shrink();
                        final stage = navToPickup ? 'To Pickup' : 'To Dropoff';
                        return Text('Stage: ' + stage);
                      },
                    ),
                    Builder(
                      builder: (_) {
                        final cost = routeFare;
                        if (cost == null) return const SizedBox.shrink();
                        return Text(
                          'Cost: R ' + cost.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (o != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Starting navigation...'),
                                  ),
                                );
                                await _startNavigation();
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
