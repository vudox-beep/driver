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
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'dart:ui' as ui;

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
  gmap.GoogleMapController? _gmap;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolylineAnnotationManager? _polylineManager;
  _PointClick? _tapListener;
  List<LatLng> routePoints = const [];
  double? routeDistanceKm;
  double? routeFare;
  double? routeEtaMinutes;
  static const double _ratePerKm = 5.0;
  LatLng? userCoord;
  String? userAddress;
  StreamSubscription<Position>? _posSub;
  bool navToPickup = false;
  final Distance _distCalc = const Distance();
  Timer? _simTimer;
  bool showInfoOverlay = false;
  gmap.BitmapDescriptor? _carIcon;
  bool _didInitialFit = false;
  bool _deliveredDone = false;
  bool _didScheduleAutoStart = false;
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
  bool _fareLocked = false;
  double? _fareFixed;
  LatLng? _displayCoord;
  LatLng? _snappedCoord;
  double _kmToMiles(double km) => km * 0.621371;
  double? _speedKmh;
  LatLng? _lastSpeedCoord;
  DateTime? _lastSpeedTime;
  static const double _fixedZoom = 16.5;
  double _currentZoom = _fixedZoom;
  double? _pickupDistMeters;
  bool _pickupApproachSpoken = false;
  static const String _googleDarkStyleJson =
      '[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},{"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},{"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},{"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},{"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#1a3646"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#1f2835"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}]';

  double _smoothZoom(double target) {
    final z = _currentZoom + (target - _currentZoom) * 0.15;
    return z.clamp(3.0, 20.0);
  }

  FlutterTts? _tts;
  bool _voiceEnabled = false;
  int? _spokenStepIndex;
  int? _approachSpokenIndex;

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
        final cost =
            _fareFixed ??
            routeFare ??
            ((o?.payout ?? 0.0) > 0 ? o!.payout : null);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.78),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (cust.isNotEmpty)
                      Text(
                        'Customer: ' + cust,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (address.isNotEmpty)
                      Text(
                        'Address: ' + address,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (routeDistanceKm != null)
                      Text(
                        'Distance: ' +
                            routeDistanceKm!.toStringAsFixed(1) +
                            ' km',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (cost != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cost: R ' + cost.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        _maybeSpeakTurn();
      } else {
        setState(() {
          _stepDistMeters = d;
        });
        _maybeSpeakApproach();
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
    AppMeta.ensureGoogleApiKeyLoaded();
    _ensureLocation();
    _startPositionStream();
    _load();
    _initTts();
    _buildCarIcon();
  }

  Future<void> _buildCarIcon() async {
    try {
      final size = 96.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
      final body = ui.Paint()..color = const Color(0xFFFF9800);
      final dark = ui.Paint()..color = const Color(0xFF212121);
      final glass = ui.Paint()..color = const Color(0xFF90CAF9);
      final accent = ui.Paint()..color = const Color(0xFFE65100);
      final w = size;
      final h = size;
      final bx = w * 0.22;
      final by = h * 0.56;
      final bw = w * 0.56;
      final bh = h * 0.22;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(bx, by, bw, bh),
          ui.Radius.circular(h * 0.08),
        ),
        body,
      );
      final roof = ui.Path();
      roof.moveTo(w * 0.30, h * 0.56);
      roof.lineTo(w * 0.40, h * 0.46);
      roof.lineTo(w * 0.60, h * 0.46);
      roof.lineTo(w * 0.68, h * 0.56);
      roof.close();
      canvas.drawPath(roof, glass);
      final nose = ui.Path();
      nose.moveTo(w * 0.78, h * 0.60);
      nose.lineTo(w * 0.78, h * 0.74);
      nose.lineTo(w * 0.88, h * 0.67);
      nose.close();
      canvas.drawPath(nose, accent);
      canvas.drawCircle(ui.Offset(w * 0.34, h * 0.80), h * 0.06, dark);
      canvas.drawCircle(ui.Offset(w * 0.66, h * 0.80), h * 0.06, dark);
      final pic = recorder.endRecording();
      final img = await pic.toImage(size.toInt(), size.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        final d = gmap.BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
        setState(() => _carIcon = d);
      }
    } catch (_) {}
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

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setPitch(1.0);
      await _tts!.setSpeechRate(0.5);
      try {
        await _pickPleasantVoice();
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (_tts == null || !_voiceEnabled) return;
    try {
      await _tts!.speak(text);
    } catch (_) {}
  }

  Future<void> _pickPleasantVoice() async {
    if (_tts == null) return;
    try {
      final voices = await _tts!.getVoices;
      List<Map<String, dynamic>> list = [];
      if (voices is List) {
        for (final v in voices) {
          if (v is Map) {
            list.add(v.map((k, val) => MapEntry(k.toString(), val)));
          }
        }
      }
      Map<String, dynamic>? chosen;
      for (final v in list) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final loc = (v['locale'] ?? '').toString().toLowerCase();
        if (loc.startsWith('en-us') && name.contains('female')) {
          chosen = v;
          break;
        }
      }
      chosen ??= list.firstWhere((v) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final loc = (v['locale'] ?? '').toString().toLowerCase();
        return loc.startsWith('en-gb') && name.contains('female');
      }, orElse: () => {});
      if ((chosen ?? {}).isEmpty) {
        chosen = list.firstWhere(
          (v) =>
              ((v['locale'] ?? '').toString().toLowerCase()).startsWith('en'),
          orElse: () => (list.isNotEmpty ? list.first : {}),
        );
      }
      final name = (chosen?['name'] ?? '').toString();
      final locale = (chosen?['locale'] ?? '').toString();
      if (name.isNotEmpty && locale.isNotEmpty) {
        await _tts!.setVoice({'name': name, 'locale': locale});
      }
      try {
        await _tts!.setPitch(1.05);
      } catch (_) {}
      try {
        await _tts!.setSpeechRate(0.46);
      } catch (_) {}
    } catch (_) {}
  }

  String _formatInstruction(String? type, String? modifier, String name) {
    final t = (type ?? '').toLowerCase();
    final m = (modifier ?? '').toLowerCase();
    final n = name.trim();
    if (t == 'arrive') return 'Arrive at destination';
    if (t == 'depart') return 'Head to pickup';
    if (t == 'continue')
      return 'Continue straight' + (n.isNotEmpty ? ' on ' + n : '');
    if (t == 'uturn') return 'Make a U turn';
    if (t == 'roundabout')
      return 'Enter roundabout' + (n.isNotEmpty ? ' to ' + n : '');
    if (t == 'turn') {
      if (m.contains('left'))
        return 'Turn left' + (n.isNotEmpty ? ' onto ' + n : '');
      if (m.contains('right'))
        return 'Turn right' + (n.isNotEmpty ? ' onto ' + n : '');
      return 'Follow route' + (n.isNotEmpty ? ' on ' + n : '');
    }
    return 'Follow route' + (n.isNotEmpty ? ' on ' + n : '');
  }

  Future<void> _maybeSpeakTurn() async {
    if (!_voiceEnabled || !_started) return;
    if (_steps.isEmpty) return;
    final i = _stepIndex;
    if (_spokenStepIndex == i) return;
    _spokenStepIndex = i;
    final s = _steps[i];
    final text = _formatInstruction(s.type, s.modifier, s.name);
    await _speak(text);
  }

  Future<void> _maybeSpeakApproach() async {
    if (!_voiceEnabled || !_started) return;
    if (_steps.isEmpty || userCoord == null) return;
    final i = _stepIndex;
    if (_approachSpokenIndex == i) return;
    final s = _steps[i];
    if (s.geom.isEmpty) return;
    final end = s.geom.last;
    final d = _distCalc.as(LengthUnit.Meter, userCoord!, end);
    if (d <= 110 && d >= 90) {
      _approachSpokenIndex = i;
      String base = _formatInstruction(s.type, s.modifier, s.name);
      final text = 'In one hundred meters, ' + base.toLowerCase();
      await _speak(text);
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
    setState(() {
      _voiceEnabled = true;
      _spokenStepIndex = null;
      _approachSpokenIndex = null;
      _pickupApproachSpoken = false;
      if (o.payout > 0) {
        _fareFixed = o.payout;
        _fareLocked = true;
        routeFare = o.payout;
      }
    });
    await _speak('Starting navigation');
    if (DriverSession.mapboxToken.isNotEmpty) {
      setState(() {
        fromCoord = from;
        toCoord = to;
      });
      if (userCoord != null) {
        navToPickup = from != null;
        await _recalcRouteFromUser();
        if (mounted) setState(() => showInfoOverlay = true);
      } else {
        if (from != null && to != null) {
          final ok = await _fetchRoute(from, to);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to get directions')),
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
    final gKey = DriverSession.googleMapsApiKey;
    final hasToken = DriverSession.mapboxToken.isNotEmpty;
    try {
      if ((gKey).isNotEmpty) {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${from.latitude},${from.longitude}&destination=${to.latitude},${to.longitude}&mode=driving&alternatives=false&units=metric&key=' +
              gKey,
        );
        final headers = await AppMeta.androidAuthHeaders();
        final res = await http
            .get(
              url,
              headers: {
                ...headers,
                'User-Agent': 'driver-app/1.0',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map &&
              data['routes'] is List &&
              (data['routes'] as List).isNotEmpty) {
            final route = (data['routes'] as List).first as Map;
            final overview =
                (route['overview_polyline'] as Map?)?['points']?.toString() ??
                '';
            final pts = overview.isNotEmpty
                ? _decodePolyline5(overview)
                : const <LatLng>[];
            if (pts.isNotEmpty) {
              setState(() {
                routePoints = pts;
                double? distMeters;
                double? durSecs;
                final legs = route['legs'];
                if (legs is List && legs.isNotEmpty) {
                  final leg = legs.first as Map;
                  distMeters = ((leg['distance'] as Map?)?['value'] as num?)
                      ?.toDouble();
                  durSecs = ((leg['duration'] as Map?)?['value'] as num?)
                      ?.toDouble();
                  final st = leg['steps'];
                  final built = <_NavStep>[];
                  if (st is List && st.isNotEmpty) {
                    for (final e in st) {
                      if (e is Map) {
                        final name = _clean(
                          (e['html_instructions'] ?? '').toString(),
                        );
                        final dm =
                            ((e['distance'] as Map?)?['value'] as num?)
                                ?.toDouble() ??
                            0.0;
                        final man = (e['maneuver'] ?? '')
                            .toString()
                            .toLowerCase();
                        String type = 'continue';
                        String modifier = '';
                        if (man.contains('turn')) {
                          type = 'turn';
                          if (man.contains('left')) modifier = 'left';
                          if (man.contains('right')) modifier = 'right';
                        } else if (man.contains('roundabout')) {
                          type = 'roundabout';
                        } else if (man.contains('arrive')) {
                          type = 'arrive';
                        } else if (man.contains('depart')) {
                          type = 'depart';
                        }
                        final gstr =
                            ((e['polyline'] as Map?)?['points']?.toString() ??
                            '');
                        final g = gstr.isNotEmpty
                            ? _decodePolyline5(gstr)
                            : const <LatLng>[];
                        built.add(_NavStep(name, dm, type, modifier, g));
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
                    _spokenStepIndex = null;
                  } else {
                    _stepName = null;
                    _stepDistMeters = null;
                    _stepType = null;
                    _stepModifier = null;
                    _stepGeom = const [];
                  }
                }
                if (distMeters != null) {
                  routeDistanceKm = distMeters! / 1000.0;
                  if (durSecs != null) {
                    routeEtaMinutes = durSecs! / 60.0;
                  } else {
                    routeEtaMinutes = null;
                  }
                  final newFare = routeDistanceKm! * _ratePerKm;
                  if (_fareLocked) {
                    routeFare = _fareFixed;
                  } else {
                    routeFare = newFare;
                    if (_started) {
                      _fareFixed = newFare;
                      _fareLocked = true;
                    }
                  }
                } else {
                  routeDistanceKm = null;
                  routeEtaMinutes = null;
                  if (!_fareLocked) routeFare = null;
                }
              });
              await _maybeSpeakTurn();
              return true;
            }
          }
        }
      }
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
                  final newFare = routeDistanceKm! * _ratePerKm;
                  if (_fareLocked) {
                    routeFare = _fareFixed;
                  } else {
                    routeFare = newFare;
                    if (_started) {
                      _fareFixed = newFare;
                      _fareLocked = true;
                    }
                  }
                } else {
                  routeDistanceKm = null;
                  if (!_fareLocked) routeFare = null;
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
                    _spokenStepIndex = null;
                  } else {
                    _stepName = null;
                    _stepDistMeters = null;
                    _stepType = null;
                    _stepModifier = null;
                    _stepGeom = const [];
                  }
                }
              });
              await _maybeSpeakTurn();
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
                  final newFare = routeDistanceKm! * _ratePerKm;
                  if (_fareLocked) {
                    routeFare = _fareFixed;
                  } else {
                    routeFare = newFare;
                    if (_started) {
                      _fareFixed = newFare;
                      _fareLocked = true;
                    }
                  }
                } else {
                  routeDistanceKm = null;
                  if (!_fareLocked) routeFare = null;
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
        final newFare = km * _ratePerKm;
        if (_fareLocked) {
          routeFare = _fareFixed;
        } else {
          routeFare = newFare;
          if (_started) {
            _fareFixed = newFare;
            _fareLocked = true;
          }
        }
      });
      await _syncMapboxAnnotations();
      await _fitCameraToTargetsIfNeeded();
      return true;
    } catch (_) {}
    return false;
  }

  List<LatLng> _decodePolyline5(String encoded) {
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
      final latD = lat / 1e5;
      final lngD = lng / 1e5;
      coords.add(LatLng(latD, lngD));
    }
    return coords;
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
    final reached = _distCalc.as(LengthUnit.Meter, userCoord!, target) < 80;
    if (reached && navToPickup) {
      navToPickup = false;
      target = toCoord;
      final o = widget.order;
      if (o != null) {
        try {
          await ApiClient.updateOrderStatus(
            o.id,
            'picked_up',
            action: 'update_status',
            extra: {
              'driver_pickup_time': ApiClient.nowTs(),
              'fee': _fareFixed ?? routeFare,
              'delivery_fee': _fareFixed ?? routeFare,
            },
          );
        } catch (_) {}
      }
      await _speak('Pickup complete. Navigating to dropoff');
    }
    if (target != null) {
      await _fetchRoute(userCoord!, target);
    }
  }

  Future<void> _fitCameraToTargets() async {
    LatLng? center;
    if (userCoord != null) {
      center = userCoord!;
    } else {
      final pts = <LatLng>[];
      if (routePoints.isNotEmpty) {
        pts.addAll(routePoints);
      } else {
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
      center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    }
    final zoom = _fixedZoom;
    double? brg;
    if (fromCoord != null && toCoord != null) {
      brg = _bearing(fromCoord!, toCoord!);
    }
    if (_mapbox != null) {
      await _mapbox!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(center!.longitude, center.latitude),
          ),
          zoom: zoom,
          pitch: 55,
          bearing: brg,
        ),
      );
      _currentZoom = zoom;
    } else {
      mapController.move(center!, zoom);
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
          lineWidth: 12.0,
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
            final prevDisplay = _displayCoord ?? prevCoord;
            _displayCoord = prevDisplay == null
                ? cur
                : LatLng(
                    prevDisplay.latitude +
                        (cur.latitude - prevDisplay.latitude) * 0.20,
                    prevDisplay.longitude +
                        (cur.longitude - prevDisplay.longitude) * 0.20,
                  );
            if (routePoints.isNotEmpty && _displayCoord != null) {
              final snap = _snapToRoute(_displayCoord!);
              if (snap != null) _snappedCoord = snap;
            } else {
              _snappedCoord = null;
            }
            setState(() {
              userCoord = cur;
              centerCoord = _snappedCoord ?? _displayCoord;
              if (kmh != null) _speedKmh = kmh;
              if (navToPickup && fromCoord != null) {
                _pickupDistMeters = _distCalc.as(
                  LengthUnit.Meter,
                  cur,
                  fromCoord!,
                );
              } else {
                _pickupDistMeters = null;
                _pickupApproachSpoken = false;
              }
            });
            if (navToPickup && fromCoord != null && _voiceEnabled && _started) {
              final pd =
                  _pickupDistMeters ??
                  _distCalc.as(LengthUnit.Meter, cur, fromCoord!);
              if (!_pickupApproachSpoken && pd < 120 && pd > 60) {
                _pickupApproachSpoken = true;
                await _speak('In one hundred meters, pickup');
              }
            }
            final shouldFollow = _started || ((_speedKmh ?? 0.0) > 0.5);
            if (_gmap != null) {
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
                if (moveMeters > 2.0 || dtCam > 450) {
                  final newBearing = targetBrg ?? _lastBearing ?? 0.0;
                  await _gmap!.animateCamera(
                    gmap.CameraUpdate.newCameraPosition(
                      gmap.CameraPosition(
                        target: gmap.LatLng(
                          (centerCoord ?? userCoord!)!.latitude,
                          (centerCoord ?? userCoord!)!.longitude,
                        ),
                        zoom: _currentZoom,
                        tilt: 55,
                        bearing: newBearing,
                      ),
                    ),
                  );
                  _lastBearing = newBearing;
                  _lastCamUpdate = now;
                  if (_started) {
                    await _recalcRouteFromUser();
                    _updateCurrentStep();
                  }
                }
              }
            } else if (_mapbox != null) {
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
                if (moveMeters > 2.0 || dtCam > 450) {
                  final targetBearing = targetBrg ?? _lastBearing ?? 0.0;
                  double newBearing;
                  if (_lastBearing == null) {
                    newBearing = targetBearing;
                  } else {
                    var diff = targetBearing - _lastBearing!;
                    while (diff > 180.0) diff -= 360.0;
                    while (diff < -180.0) diff += 360.0;
                    final step = diff.clamp(-6.0, 6.0);
                    newBearing = _lastBearing! + step;
                  }
                  await _mapbox!.flyTo(
                    mapbox.CameraOptions(
                      center: mapbox.Point(
                        coordinates: mapbox.Position(
                          (centerCoord ?? userCoord!)!.longitude,
                          (centerCoord ?? userCoord!)!.latitude,
                        ),
                      ),
                      zoom: _currentZoom,
                      pitch: 55,
                      bearing: newBearing,
                    ),
                    mapbox.MapAnimationOptions(duration: 650, startDelay: 0),
                  );
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
                if (moveMeters > 2.0 || dtCam > 450) {
                  final gpsBrg = pos.heading;
                  if (gpsBrg.isFinite && gpsBrg >= 0) {
                    _lastBearing = gpsBrg;
                  }
                  mapController.move(centerCoord ?? userCoord!, _currentZoom);
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
        if (Navigator.canPop(context)) {
          Navigator.pop(context, {'started': _started});
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Navigation')),
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => showInfoOverlay = !showInfoOverlay),
                child: (DriverSession.googleMapsApiKey.isNotEmpty)
                    ? gmap.GoogleMap(
                        mapType: gmap.MapType.normal,
                        initialCameraPosition: gmap.CameraPosition(
                          target: gmap.LatLng(
                            (userCoord ??
                                    centerCoord ??
                                    fromCoord ??
                                    toCoord ??
                                    const LatLng(-26.2041, 28.0473))
                                .latitude,
                            (userCoord ??
                                    centerCoord ??
                                    fromCoord ??
                                    toCoord ??
                                    const LatLng(-26.2041, 28.0473))
                                .longitude,
                          ),
                          zoom: _fixedZoom,
                          tilt: 55,
                          bearing: 0,
                        ),
                        onMapCreated: (c) async {
                          _gmap = c;
                          try {
                            await _gmap!.setMapStyle(_googleDarkBlueStyleJson);
                          } catch (_) {}
                          if (widget.autoStart) {
                            await _startNavigation();
                          }
                        },
                        markers: _gmapMarkers(),
                        polylines: _gmapPolylines(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        trafficEnabled: false,
                        zoomControlsEnabled: false,
                        tiltGesturesEnabled: true,
                        buildingsEnabled: true,
                        indoorViewEnabled: true,
                      )
                    : fmap.FlutterMap(
                        mapController: mapController,
                        options: fmap.MapOptions(
                          initialCenter: (userCoord ??
                                  centerCoord ??
                                  fromCoord ??
                                  toCoord ??
                                  const LatLng(-26.2041, 28.0473)),
                          initialZoom: _fixedZoom,
                        ),
                        children: [
                          fmap.TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          fmap.PolylineLayer(
                            polylines: [
                              if (routePoints.isNotEmpty)
                                fmap.Polyline(
                                  points: routePoints,
                                  color: const Color(0xFF4285F4),
                                  strokeWidth: 6,
                                ),
                            ],
                          ),
                          fmap.MarkerLayer(
                            markers: [
                              if (fromCoord != null)
                                fmap.Marker(
                                  point: fromCoord!,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.orange,
                                  ),
                                ),
                              if (toCoord != null)
                                fmap.Marker(
                                  point: toCoord!,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              if ((
                                      _snappedCoord ?? _displayCoord ?? userCoord) !=
                                  null)
                                fmap.Marker(
                                  point:
                                      (_snappedCoord ?? _displayCoord ?? userCoord)!,
                                  width: 36,
                                  height: 36,
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.deepOrange,
                                  ),
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
            if (!DriverSession.googleMapsApiKey.isNotEmpty &&
                widget.autoStart &&
                !_didScheduleAutoStart)
              Builder(
                builder: (_) {
                  _didScheduleAutoStart = true;
                  Future.microtask(() async {
                    await _startNavigation();
                  });
                  return const SizedBox.shrink();
                },
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
            Positioned(
              top: 56,
              left: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    (navToPickup &&
                        _pickupDistMeters != null &&
                        _pickupDistMeters! <= 200 &&
                        _pickupDistMeters! > 40)
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.store, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Near pickup ' +
                                  _pickupDistMeters!.toStringAsFixed(0) +
                                  ' m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
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
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      color: Colors.white,
                      icon: Icon(
                        showInfoOverlay
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => showInfoOverlay = !showInfoOverlay),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      color: Colors.white,
                      icon: Icon(
                        _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      ),
                      onPressed: () async {
                        setState(() => _voiceEnabled = !_voiceEnabled);
                        if (_voiceEnabled) await _speak('Voice guidance on');
                      },
                    ),
                  ],
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
                            if (o != null && (o.foodType ?? '').isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _clean(o.foodType!),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (o != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _clean(o.customerName),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.phone,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () async {
                                      String phone = (o.customerPhone ?? '')
                                          .trim();
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
                                      if (phone.isEmpty) return;
                                      final uri = Uri.parse('tel:' + phone);
                                      try {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {}
                                    },
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.store, color: Colors.white70),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    o != null ? _clean(o.pickupAddress) : '-',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place, color: Colors.white70),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    o != null ? _clean(o.deliveryAddress) : '-',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (_) {
                                final dist = routeDistanceKm ?? o?.distanceKm;
                                if (dist == null)
                                  return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.straighten,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dist.toStringAsFixed(1) + ' km',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (routeEtaMinutes != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    routeEtaMinutes!.toStringAsFixed(0) +
                                        ' min',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            if (userCoord != null)
                              Row(
                                children: [
                                  const Icon(Icons.flag, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    navToPickup ? 'To Pickup' : 'To Dropoff',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            if (routeFare != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.attach_money,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'R ' + routeFare!.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            if (o != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'R ' + o.payout.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                                          if (mounted) {
                                            if (Navigator.canPop(context)) {
                                              Navigator.pop(context, {
                                                'started': _started,
                                              });
                                            } else {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/dashboard',
                                              );
                                            }
                                          }
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
                                        onPressed:
                                            (o == null ||
                                                _deliveredDone ||
                                                ((o.status).toLowerCase() ==
                                                    'delivered'))
                                            ? null
                                            : () async {
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
                                                      await ApiClient.markDeliveredOrdersPhp(
                                                        o.id,
                                                        fee: routeFare,
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
                                                            : (ApiClient
                                                                      .lastError ??
                                                                  'Failed to update delivery'),
                                                      ),
                                                    ),
                                                  );
                                                  if (ok && mounted) {
                                                    setState(
                                                      () =>
                                                          _deliveredDone = true,
                                                    );
                                                    if (Navigator.canPop(
                                                      context,
                                                    )) {
                                                      Navigator.pop(context, {
                                                        'started': _started,
                                                      });
                                                    } else {
                                                      Navigator.pushReplacementNamed(
                                                        context,
                                                        '/dashboard',
                                                      );
                                                    }
                                                  }
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

  Set<gmap.Marker> _gmapMarkers() {
    final m = <gmap.Marker>{};
    final o = widget.order;
    if (fromCoord != null) {
      m.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('pickup'),
          position: gmap.LatLng(fromCoord!.latitude, fromCoord!.longitude),
          infoWindow: gmap.InfoWindow(
            title: o != null ? 'Pickup: ' + _clean(o.pickupAddress) : 'Pickup',
          ),
        ),
      );
    }
    if (toCoord != null) {
      m.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('dropoff'),
          position: gmap.LatLng(toCoord!.latitude, toCoord!.longitude),
          infoWindow: gmap.InfoWindow(
            title: o != null
                ? 'Dropoff: ' + _clean(o.deliveryAddress)
                : 'Dropoff',
          ),
        ),
      );
    }
    final uc = (_snappedCoord ?? _displayCoord ?? userCoord);
    if (uc != null) {
      m.add(
        gmap.Marker(
          markerId: const gmap.MarkerId('driver'),
          position: gmap.LatLng(uc.latitude, uc.longitude),
          rotation: (_lastBearing ?? 0.0),
          icon:
              _carIcon ??
              gmap.BitmapDescriptor.defaultMarkerWithHue(
                gmap.BitmapDescriptor.hueOrange,
              ),
        ),
      );
    }
    return m;
  }

  Set<gmap.Polyline> _gmapPolylines() {
    if (routePoints.isEmpty) return const <gmap.Polyline>{};
    return {
      gmap.Polyline(
        polylineId: const gmap.PolylineId('route'),
        points: routePoints
            .map((e) => gmap.LatLng(e.latitude, e.longitude))
            .toList(),
        width: 10,
        color: const Color(0xFF4285F4),
        geodesic: true,
      ),
    };
  }

  Future<void> _zoomBy(double delta) async {
    final z = (_currentZoom + delta).clamp(3.0, 20.0);
    _currentZoom = z;
    if (_gmap != null) {
      await _gmap!.animateCamera(gmap.CameraUpdate.zoomTo(z));
    } else if (_mapbox != null) {
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

  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;
    final vx = bx - ax;
    final vy = by - ay;
    final wx = px - ax;
    final wy = py - ay;
    final denom = (vx * vx) + (vy * vy);
    double t = denom == 0.0 ? 0.0 : ((wx * vx) + (wy * vy)) / denom;
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    return LatLng(ay + vy * t, ax + vx * t);
  }

  LatLng? _snapToRoute(LatLng p) {
    if (routePoints.isEmpty) return null;
    LatLng best = routePoints.first;
    double bestD = _distCalc.as(LengthUnit.Meter, p, best);
    for (int i = 0; i < routePoints.length - 1; i++) {
      final a = routePoints[i];
      final b = routePoints[i + 1];
      final proj = _projectOnSegment(p, a, b);
      final d = _distCalc.as(LengthUnit.Meter, p, proj);
      if (d < bestD) {
        bestD = d;
        best = proj;
      }
    }
    return best;
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

const String _googleDarkBlueStyleJson =
    '[{"elementType":"geometry","stylers":[{"color":"#1b2a49"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8aa1b1"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#0f1a2b"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2a3e66"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#12223b"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f8aa5"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0e1e34"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c406e"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9bb3c9"}]},{"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#0f1a2b"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2a5f8a"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1e486a"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1a2e50"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#7b94ad"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1324"}]}]';
