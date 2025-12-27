import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../theme.dart';
import '../services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

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
  Timer? _simTimer;
  bool showInfoOverlay = false;
  bool _didInitialFit = false;
  List<_NavStep> _steps = const [];
  int _stepIndex = 0;
  String? _stepName;
  double? _stepDistMeters;
  String? _stepType;
  String? _stepModifier;
  List<LatLng> _stepGeom = const [];
  bool _started = false;
  DateTime? _lastCamUpdate;
  double? _lastBearing;
  double _kmToMiles(double km) => km * 0.621371;
  double? _speedKmh;
  LatLng? _lastSpeedCoord;
  DateTime? _lastSpeedTime;
  double _currentZoom = 15.0;

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

  IconData _turnIconFor(String? type, String? modifier) {
    final t = (type ?? '').toLowerCase();
    final m = (modifier ?? '').toLowerCase();
    if (t == 'turn') {
      if (m.contains('left')) return Icons.keyboard_arrow_left;
      if (m.contains('right')) return Icons.keyboard_arrow_right;
      return Icons.navigation;
    }
    if (t == 'depart' || t == 'continue') return Icons.arrow_upward;
    if (t == 'arrive') return Icons.flag;
    if (t == 'uturn') return Icons.keyboard_return;
    if (t == 'roundabout') return Icons.sync;
    return Icons.navigation;
  }

  double? _nextTurnDistanceMiles() {
    if (userCoord != null && _stepGeom.isNotEmpty) {
      final end = _stepGeom.last;
      final km = _distCalc.as(LengthUnit.Kilometer, userCoord!, end);
      return _kmToMiles(km);
    }
    if (_stepDistMeters != null) return _stepDistMeters! / 1609.34;
    return routeDistanceKm != null ? _kmToMiles(routeDistanceKm!) : null;
  }

  void _updateCurrentStep() {
    if (userCoord == null || _steps.isEmpty) return;
    final s = _steps[_stepIndex];
    if (s.geom.isNotEmpty) {
      final end = s.geom.last;
      final d = _distCalc.as(LengthUnit.Meter, userCoord!, end);
      if (d < 30 && _stepIndex < _steps.length - 1) {
        final ns = _steps[_stepIndex + 1];
        setState(() {
          _stepIndex = _stepIndex + 1;
          _stepName = ns.name;
          _stepDistMeters = ns.distance;
          _stepType = ns.type;
          _stepModifier = ns.modifier;
          _stepGeom = ns.geom;
        });
      } else {
        setState(() {
          _stepDistMeters = d;
        });
      }
    }
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
    _started = true;
    if (DriverSession.mapboxToken.isNotEmpty) {
      setState(() {
        fromCoord = from;
        toCoord = to;
      });
      if (userCoord != null) {
        navToPickup = from != null;
        await _recalcRouteFromUser();
        if (routeFare != null) {
          await ApiClient.updateOrderStatus(
            o.id,
            'picked_up',
            action: 'update_status',
            extra: {
              'driver_pickup_time': ApiClient.nowTs(),
              'fee': routeFare,
              'delivery_fee': routeFare,
            },
          );
        }
        if (mounted) setState(() => showInfoOverlay = true);
      } else {
        if (from != null && to != null) {
          final ok = await _fetchRoute(from, to);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to get directions')),
            );
          }
          if (routeFare != null) {
            await ApiClient.updateOrderStatus(
              o.id,
              'picked_up',
              action: 'update_status',
              extra: {
                'driver_pickup_time': ApiClient.nowTs(),
                'fee': routeFare,
                'delivery_fee': routeFare,
              },
            );
          }
          if (mounted) setState(() => showInfoOverlay = true);
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
      if (routeFare != null && o != null) {
        await ApiClient.updateOrderStatus(
          o.id,
          'picked_up',
          action: 'update_status',
          extra: {
            'driver_pickup_time': ApiClient.nowTs(),
            'fee': routeFare,
            'delivery_fee': routeFare,
          },
        );
      }
      if (mounted) setState(() => showInfoOverlay = true);
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
    final hasToken = DriverSession.mapboxToken.isNotEmpty;
    try {
      if (hasToken) {
        final url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?geometries=polyline6&steps=true&overview=full&access_token=${DriverSession.mapboxToken}',
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
                final legs = route['legs'];
                if (legs is List && legs.isNotEmpty) {
                  final leg = legs.first as Map;
                  final st = leg['steps'];
                  final built = <_NavStep>[];
                  if (st is List && st.isNotEmpty) {
                    for (final e in st) {
                      if (e is Map) {
                        final name = (e['name'] ?? '').toString();
                        final dm = (e['distance'] as num?)?.toDouble() ?? 0.0;
                        final man = e['maneuver'] as Map?;
                        final type = (man?['type'] ?? '').toString();
                        final mod = (man?['modifier'] ?? '').toString();
                        final gstr = (e['geometry'] ?? '').toString();
                        final g = gstr.isNotEmpty
                            ? _decodePolyline6(gstr)
                            : const <LatLng>[];
                        built.add(_NavStep(name, dm, type, mod, g));
                      }
                    }
                  }
                  _steps = built;
                  _stepIndex = 0;
                  if (_steps.isNotEmpty) {
                    final s = _steps.first;
                    _stepName = s.name;
                    _stepDistMeters = s.distance;
                    _stepType = s.type;
                    _stepModifier = s.modifier;
                    _stepGeom = s.geom;
                  } else {
                    _stepName = null;
                    _stepDistMeters = null;
                    _stepType = null;
                    _stepModifier = null;
                    _stepGeom = const [];
                  }
                }
              });
              if (_mapbox != null) {
                await _syncMapboxAnnotations();
                await _fitCameraToTargetsIfNeeded();
              }
              return true;
            }
          }
        }
      } else {
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=polyline6',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 15));
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
              await _syncMapboxAnnotations();
              await _fitCameraToTargetsIfNeeded();
              return true;
            }
          }
        }
      }
    } catch (_) {}
    try {
      final km = _distCalc.as(LengthUnit.Kilometer, from, to);
      setState(() {
        routePoints = [from, to];
        routeDistanceKm = km;
        routeFare = km * _ratePerKm;
      });
      await _syncMapboxAnnotations();
      await _fitCameraToTargetsIfNeeded();
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
      zoom = 16;
    } else if (span < 0.05) {
      zoom = 15;
    } else if (span < 0.2) {
      zoom = 13;
    } else if (span < 1.0) {
      zoom = 11;
    } else {
      zoom = 9;
    }
    double? brg;
    if (fromCoord != null && toCoord != null) {
      brg = _bearing(fromCoord!, toCoord!);
    }
    if (_mapbox != null) {
      await _mapbox!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(center.longitude, center.latitude),
          ),
          zoom: zoom,
          pitch: 55,
          bearing: brg,
        ),
      );
      _currentZoom = zoom;
    } else {
      mapController.move(center, zoom);
    }
  }

  Future<void> _fitCameraToTargetsIfNeeded() async {
    if (!_didInitialFit) {
      await _fitCameraToTargets();
      _didInitialFit = true;
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

    _tapListener ??= _PointClick(_onPointAnnotationTap);
    _pointManager!.addOnPointAnnotationClickListener(_tapListener!);
    if (routePoints.isNotEmpty) {
      final coords = routePoints
          .map((e) => mapbox.Position(e.longitude, e.latitude))
          .toList(growable: false);
      await _polylineManager!.create(
        mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: coords),
          lineWidth: 8.0,
          lineColor: const Color(0xFF00A3FF).value,
          lineOpacity: 0.95,
        ),
      );
    }
    await _fitCameraToTargetsIfNeeded();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _simTimer?.cancel();
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
            final now = DateTime.now();
            final cur = LatLng(pos.latitude, pos.longitude);
            double? kmh;
            final sp = pos.speed;
            if (sp != null && sp >= 0) {
              kmh = sp * 3.6;
            } else if (_lastSpeedCoord != null && _lastSpeedTime != null) {
              final d = _distCalc.as(LengthUnit.Meter, _lastSpeedCoord!, cur);
              final dt =
                  now.difference(_lastSpeedTime!).inMilliseconds / 1000.0;
              if (dt > 0) kmh = (d / dt) * 3.6;
            }
            final prevCoord = _lastSpeedCoord;
            _lastSpeedCoord = cur;
            _lastSpeedTime = now;
            setState(() {
              userCoord = cur;
              centerCoord = userCoord;
              if (kmh != null) _speedKmh = kmh;
            });
            final shouldFollow = _started || ((_speedKmh ?? 0.0) > 0.5);
            if (_mapbox != null) {
              if (shouldFollow) {
                double? targetBrg;
                final gpsBrg = pos.heading;
                if (gpsBrg.isFinite && gpsBrg >= 0) {
                  targetBrg = gpsBrg;
                } else if (_stepGeom.isNotEmpty) {
                  targetBrg = _bearing(userCoord!, _stepGeom.last);
                } else if (toCoord != null) {
                  targetBrg = _bearing(userCoord!, toCoord!);
                }
                final moveMeters = prevCoord == null
                    ? 9999.0
                    : _distCalc.as(LengthUnit.Meter, prevCoord, cur);
                final dtCam = _lastCamUpdate == null
                    ? 9999
                    : now.difference(_lastCamUpdate!).inMilliseconds;
                if (moveMeters > 3.0 || dtCam > 500) {
                  final targetBearing = targetBrg ?? _lastBearing ?? 0.0;
                  double newBearing;
                  if (_lastBearing == null) {
                    newBearing = targetBearing;
                  } else {
                    var diff = targetBearing - _lastBearing!;
                    while (diff > 180.0) diff -= 360.0;
                    while (diff < -180.0) diff += 360.0;
                    final step = diff.clamp(-10.0, 10.0);
                    newBearing = _lastBearing! + step;
                  }
                  final zoom = _speedKmh == null
                      ? 16.0
                      : (_speedKmh! < 10
                            ? 16.5
                            : (_speedKmh! < 40 ? 15.5 : 15.0));
                  await _mapbox!.flyTo(
                    mapbox.CameraOptions(
                      center: mapbox.Point(
                        coordinates: mapbox.Position(
                          userCoord!.longitude,
                          userCoord!.latitude,
                        ),
                      ),
                      zoom: zoom,
                      pitch: 60,
                      bearing: newBearing,
                    ),
                    mapbox.MapAnimationOptions(duration: 500, startDelay: 0),
                  );
                  _currentZoom = zoom;
                  _lastBearing = newBearing;
                  _lastCamUpdate = now;
                  if (_started) {
                    await _recalcRouteFromUser();
                    _updateCurrentStep();
                  }
                }
              }
              await _syncMapboxAnnotations();
            } else {
              if (shouldFollow) {
                final moveMeters = prevCoord == null
                    ? 9999.0
                    : _distCalc.as(LengthUnit.Meter, prevCoord, cur);
                final dtCam = _lastCamUpdate == null
                    ? 9999
                    : now.difference(_lastCamUpdate!).inMilliseconds;
                if (moveMeters > 3.0 || dtCam > 500) {
                  final gpsBrg = pos.heading;
                  if (gpsBrg.isFinite && gpsBrg >= 0) {
                    _lastBearing = gpsBrg;
                  }
                  final zoom = _speedKmh == null
                      ? 16.0
                      : (_speedKmh! < 10
                            ? 16.5
                            : (_speedKmh! < 40 ? 15.5 : 15.0));
                  _currentZoom = zoom;
                  mapController.move(userCoord!, _currentZoom);
                  _lastCamUpdate = now;
                  if (_started) {
                    await _recalcRouteFromUser();
                    _updateCurrentStep();
                  }
                }
              }
            }
          });
    } catch (_) {}
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * (3.141592653589793 / 180.0);
    final lat2 = b.latitude * (3.141592653589793 / 180.0);
    final dLon = (b.longitude - a.longitude) * (3.141592653589793 / 180.0);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    var brng = math.atan2(y, x) * (180.0 / 3.141592653589793);
    brng = (brng + 360.0) % 360.0;
    return brng;
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {'started': _started});
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showInfoOverlay = !showInfoOverlay),
                child: DriverSession.mapboxToken.isNotEmpty
                    ? mapbox.MapWidget(
                        styleUri: 'mapbox://styles/mapbox/navigation-night-v1',
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
                          zoom: 15,
                          pitch: 55,
                          bearing: 0,
                        ),
                        onMapCreated: (m) async {
                          _mapbox = m;
                          try {
                            await _mapbox!.location.updateSettings(
                              mapbox.LocationComponentSettings(
                                enabled: true,
                                puckBearingEnabled: true,
                                puckBearing: mapbox.PuckBearing.COURSE,
                                locationPuck: mapbox.LocationPuck(
                                  locationPuck3D: mapbox.LocationPuck3D(
                                    modelUri:
                                        'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/CarConcept/glTF-Binary/CarConcept.glb',
                                    modelScale: [1.0, 1.0, 1.0],
                                    modelRotation: [0.0, 0.0, 0.0],
                                  ),
                                ),
                              ),
                            );
                          } catch (_) {}
                          await _syncMapboxAnnotations();
                          try {
                            await _mapbox!.style.addStyleLayer(
                              '{"id":"3d-buildings","type":"fill-extrusion","source":"composite","source-layer":"building","filter":["==",["get","extrude"],"true"],"minzoom":15,"paint":{"fill-extrusion-color":"#aaa","fill-extrusion-height":["interpolate",["linear"],["zoom"],15,0,15.05,["get","height"]],"fill-extrusion-base":["interpolate",["linear"],["zoom"],15,0,15.05,["get","min_height"]],"fill-extrusion-opacity":0.6}}',
                              null,
                            );
                            await _mapbox!.style.addStyleLayer(
                              '{"id":"sky","type":"sky","paint":{"sky-type":"atmosphere","sky-atmosphere-sun-intensity":0.5}}',
                              null,
                            );
                          } catch (_) {}
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
                                    width: 40,
                                    height: 40,
                                    child: Transform.rotate(
                                      angle:
                                          ((_lastBearing ?? 0.0) * math.pi) /
                                          180.0,
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Colors.orangeAccent,
                                        size: 34,
                                      ),
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
            ),
            if (loading)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _stepName == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(
                          _stepIndex.toString() + (_stepName ?? ''),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _turnIconFor(_stepType, _stepModifier),
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                  builder: (_) {
                                    final d = _nextTurnDistanceMiles();
                                    if (d == null)
                                      return const SizedBox.shrink();
                                    return Text(
                                      d.toStringAsFixed(1) + ' mi',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  _stepName ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (_) {
                                    final icons = <Widget>[];
                                    final end = (_stepIndex + 4) < _steps.length
                                        ? _stepIndex + 4
                                        : _steps.length - 1;
                                    for (
                                      int i = _stepIndex + 1;
                                      i <= end;
                                      i++
                                    ) {
                                      final s = _steps[i];
                                      icons.add(
                                        Icon(
                                          _turnIconFor(s.type, s.modifier),
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      );
                                      if (i < end)
                                        icons.add(const SizedBox(width: 6));
                                    }
                                    if (icons.isEmpty)
                                      return const SizedBox.shrink();
                                    return Row(children: icons);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (routeFare != null)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'R ' + routeFare!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Builder(
                builder: (_) {
                  final miles = _nextTurnDistanceMiles();
                  final step = _stepName;
                  if (miles == null && (step == null || step.isEmpty)) {
                    return const SizedBox.shrink();
                  }
                  final icons = <Widget>[];
                  final type = _stepType ?? '';
                  final mod = _stepModifier ?? '';
                  icons.add(
                    Icon(
                      _turnIconFor(type, mod),
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...icons,
                        const SizedBox(width: 8),
                        if (miles != null)
                          Text(
                            miles.toStringAsFixed(1) + ' mi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (step != null && step.isNotEmpty)
                          Text(
                            step,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (error != null)
              Positioned(
                top: 64,
                left: 16,
                right: 16,
                child: Container(
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !showInfoOverlay
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (o != null)
                              Text(
                                'Customer: ' + _clean(o.customerName),
                                style: const TextStyle(color: Colors.white),
                              ),
                            Text(
                              'From: ${o != null ? _clean(o.pickupAddress) : '-'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'To:   ${o != null ? _clean(o.deliveryAddress) : '-'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (_) {
                                final dist = routeDistanceKm ?? o?.distanceKm;
                                if (dist == null)
                                  return const SizedBox.shrink();
                                return Text(
                                  'Distance: ' +
                                      dist.toStringAsFixed(1) +
                                      ' km',
                                  style: const TextStyle(color: Colors.white70),
                                );
                              },
                            ),
                            Builder(
                              builder: (_) {
                                if (userCoord == null)
                                  return const SizedBox.shrink();
                                final stage = navToPickup
                                    ? 'To Pickup'
                                    : 'To Dropoff';
                                return Text(
                                  'Stage: ' + stage,
                                  style: const TextStyle(color: Colors.white70),
                                );
                              },
                            ),
                            if (routeFare != null)
                              Text(
                                'Cost: R ' + routeFare!.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (o != null)
                              Text(
                                'Offer: R ' + o.payout.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final btnW = w >= 560
                                    ? (w - 36) / 4
                                    : (w - 12) / 2;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      width: btnW,
                                      child: ElevatedButton(
                                        onPressed: widget.autoStart
                                            ? null
                                            : () async {
                                                if (o != null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Starting navigation...',
                                                      ),
                                                    ),
                                                  );
                                                  await _startNavigation();
                                                }
                                              },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.navigation,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              widget.autoStart
                                                  ? 'Started'
                                                  : 'Start',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: btnW,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (o != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Cancelling delivery...',
                                                ),
                                              ),
                                            );
                                            final ok =
                                                await ApiClient.updateOrderStatus(
                                                  o.id,
                                                  'awaiting',
                                                  action: 'update_status',
                                                );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Order returned to awaiting'
                                                      : 'Failed to cancel delivery',
                                                ),
                                              ),
                                            );
                                          }
                                          if (mounted)
                                            Navigator.pop(context, {
                                              'started': _started,
                                            });
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.cancel_outlined,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text('Cancel'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: btnW,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (o != null) {
                                            String phone =
                                                (o.customerPhone ?? '').trim();
                                            if (phone.isEmpty) {
                                              final fetched =
                                                  await ApiClient.fetchOrderDetailsFromOrdersPage(
                                                    o.id,
                                                  );
                                              if (fetched
                                                      ?.customerPhone
                                                      ?.isNotEmpty ==
                                                  true) {
                                                phone = fetched!.customerPhone!;
                                              }
                                            }
                                            if (phone.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No customer phone',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            final uri = Uri.parse(
                                              'tel:' + phone,
                                            );
                                            try {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } catch (_) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Unable to open dialer',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text('Call'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: btnW,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (o != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Marking delivered...',
                                                ),
                                              ),
                                            );
                                            final ok =
                                                await ApiClient.updateOrderStatus(
                                                  o.id,
                                                  'delivered',
                                                  action: 'update_status',
                                                  extra: {
                                                    'driver_delivery_time':
                                                        ApiClient.nowTs(),
                                                    if (routeFare != null)
                                                      'delivery_fee': routeFare,
                                                  },
                                                );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).hideCurrentSnackBar();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Delivery marked as complete'
                                                      : 'Failed to update delivery',
                                                ),
                                              ),
                                            );
                                            if (ok && mounted)
                                              Navigator.pop(context, {
                                                'started': _started,
                                              });
                                          }
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
                                            Text('Delivered'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final z = (_currentZoom + delta).clamp(3.0, 20.0);
    _currentZoom = z;
    if (_mapbox != null) {
      await _mapbox!.flyTo(
        mapbox.CameraOptions(zoom: z),
        mapbox.MapAnimationOptions(duration: 250, startDelay: 0),
      );
    } else {
      mapController.move(centerCoord ?? const LatLng(-26.2041, 28.0473), z);
    }
  }

  Future<void> _recenterCamera() async {
    _didInitialFit = false;
    await _fitCameraToTargetsIfNeeded();
  }
}

class _NavStep {
  final String name;
  final double distance;
  final String type;
  final String modifier;
  final List<LatLng> geom;
  const _NavStep(this.name, this.distance, this.type, this.modifier, this.geom);
}
