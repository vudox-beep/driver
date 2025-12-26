import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class RouteMap extends StatefulWidget {
  final LatLng? origin;
  final LatLng destination;
  final double? speedKmH;

  const RouteMap({
    super.key,
    this.origin,
    required this.destination,
    this.speedKmH,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _origin;
  List<LatLng> _route = [];
  LatLng? _marker;
  Timer? _timer;
  double _distanceKm = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    LatLng? start = widget.origin;
    if (start == null) {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      start = LatLng(pos.latitude, pos.longitude);
    }
    _origin = start;
    if (_origin == null) return;
    await _fetchRoute(_origin!, widget.destination);
    if (_route.isNotEmpty) {
      _marker = _route.first;
      _startAnimation();
      _centerOnRoute();
      setState(() {});
    }
  }

  Future<void> _fetchRoute(LatLng a, LatLng b) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${a.longitude},${a.latitude};${b.longitude},${b.latitude}?overview=full&geometries=polyline6',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json is Map &&
          json['routes'] is List &&
          (json['routes'] as List).isNotEmpty) {
        final r = (json['routes'] as List).first as Map;
        final poly = (r['geometry'] ?? '') as String;
        final pts = _decodePolyline(poly, 6);
        _route = pts;
        _distanceKm = ((r['distance'] ?? 0.0) as num).toDouble() / 1000.0;
      }
    }
  }

  List<LatLng> _decodePolyline(String polyline, int precision) {
    int index = 0;
    int lat = 0;
    int lng = 0;
    final coordinates = <LatLng>[];
    final factor = mathPow(10, precision);
    while (index < polyline.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      coordinates.add(LatLng(lat / factor, lng / factor));
    }
    return coordinates;
  }

  double mathPow(int base, int exp) {
    double r = 1;
    for (int i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  void _startAnimation() {
    if (_route.length < 2) return;
    _timer?.cancel();
    final speed = (widget.speedKmH ?? 40.0).clamp(5.0, 120.0);
    int i = 0;
    _marker = _route.first;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (i >= _route.length) {
        t.cancel();
        return;
      }
      _marker = _route[i];
      i++;
      setState(() {});
    });
  }

  void _centerOnRoute() {
    if (_route.isEmpty) return;
    final mid = _route[_route.length ~/ 2];
    _mapController.move(mid, 13);
  }

  @override
  Widget build(BuildContext context) {
    final polylines = _route.isNotEmpty
        ? [Polyline(points: _route, color: Colors.blueAccent, strokeWidth: 6)]
        : <Polyline>[];
    final markers = <Marker>[];
    if (_marker != null) {
      markers.add(
        Marker(
          point: _marker!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    if (_origin != null) {
      markers.add(
        Marker(
          point: _origin!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    markers.add(
      Marker(
        point: widget.destination,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.destination,
            initialZoom: 12,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} km' : '',
            ),
          ),
        ),
      ],
    );
  }
}
