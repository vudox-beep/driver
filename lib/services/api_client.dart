import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class ApiClient {
  static String? lastError;
  static String nowTs() {
    final n = DateTime.now();
    String p(int v) => v < 10 ? '0' + v.toString() : v.toString();
    return '${n.year}-${p(n.month)}-${p(n.day)} ${p(n.hour)}:${p(n.minute)}:${p(n.second)}';
  }

  static Future<int?> resolveDriverId() async {
    int? driverId = currentUser?.driverId;
    if (driverId != null) return driverId;
    try {
      if (currentUser?.userId != null) {
        final prof = await fetchProfile(currentUser!.userId);
        if (prof?.driverId != null) {
          currentUser = prof;
          return prof!.driverId;
        }
      }
    } catch (_) {}
    final tok = DriverSession.authToken ?? '';
    if (tok.isNotEmpty) {
      try {
        final uri = Uri.parse(
          ApiEndpoints.drivers,
        ).replace(queryParameters: {'token': tok});
        final res = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          Map<String, dynamic>? dd;
          if (data is Map) {
            if (data['data'] is Map) {
              dd = Map<String, dynamic>.from(data['data']);
            } else {
              dd = Map<String, dynamic>.from(data);
            }
          }
          if (dd != null) {
            final dId = dd['driver_id'];
            if (dId is int) return dId;
            if (dId is String) return int.tryParse(dId);
            if (dd['user'] is Map) {
              final u = Map<String, dynamic>.from(dd['user'] as Map);
              final v = u['driver_id'];
              if (v is int) return v;
              if (v is String) return int.tryParse(v);
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static String _s(String? v) {
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
    final lc = c.toLowerCase();
    if (lc.contains('404 not found') || lc == 'not found') return '';
    return c;
  }

  static String _normalizePhone(String? v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return '';
    final hasPlus = s.startsWith('+');
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return hasPlus ? ('+' + digits) : digits;
  }

  static Future<UserProfile?> login(String identifier, String password) async {
    final uri = Uri.parse(
      ApiEndpoints.drivers,
    ).replace(queryParameters: {'action': 'login'});
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {
            'email': identifier,
            'username': identifier,
            'password': password,
            'action': 'login',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == true) {
          final dd = (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : <String, dynamic>{};
          final u = (dd['user'] is Map)
              ? Map<String, dynamic>.from(dd['user'] as Map)
              : dd;
          final tok = (dd['token'] ?? data['token'])?.toString();
          if (tok != null && tok.isNotEmpty) {
            DriverSession.authToken = tok;
          }
          final profile = UserProfile.fromJson(u);
          currentUser = profile;
          return profile;
        }
        final msg =
            (data is Map && (data['message'] != null || data['error'] != null))
            ? (data['message'] ?? data['error']).toString()
            : 'Login failed';
        throw Exception(msg);
      } catch (e) {
        if (e is FormatException) {
          final snippet = res.body.substring(
            0,
            res.body.length > 240 ? 240 : res.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      if (res.statusCode == 401) {
        throw Exception('Incorrect email or password');
      }
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      throw Exception('HTTP ${res.statusCode}: $snippet');
    }
    final alt = Uri.parse(
      'https://' + apiHost + '/drivers/driver_api.php',
    ).replace(queryParameters: {'action': 'login'});
    final res2 = await http
        .post(
          alt,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': identifier,
            'username': identifier,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        if (data is Map && data['success'] == true) {
          final dd = (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : <String, dynamic>{};
          final u = (dd['user'] is Map)
              ? Map<String, dynamic>.from(dd['user'] as Map)
              : dd;
          final tok = (dd['token'] ?? data['token'])?.toString();
          if (tok != null && tok.isNotEmpty) {
            DriverSession.authToken = tok;
          }
          final profile = UserProfile.fromJson(u);
          currentUser = profile;
          return profile;
        }
        final msg =
            (data is Map && (data['message'] != null || data['error'] != null))
            ? (data['message'] ?? data['error']).toString()
            : 'Login failed';
        throw Exception(msg);
      } catch (e) {
        if (e is FormatException) {
          final snippet = res2.body.substring(
            0,
            res2.body.length > 240 ? 240 : res2.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      if (res2.statusCode == 401) {
        throw Exception('Incorrect email or password');
      }
      final snippet = res2.body.substring(
        0,
        res2.body.length > 240 ? 240 : res2.body.length,
      );
      throw Exception('HTTP ' + res2.statusCode.toString() + ': ' + snippet);
    }
    final res3 = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': identifier,
            'username': identifier,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res3.statusCode == 200) {
      try {
        final data = jsonDecode(res3.body);
        if (data is Map && data['success'] == true) {
          final dd = (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : <String, dynamic>{};
          final u = (dd['user'] is Map)
              ? Map<String, dynamic>.from(dd['user'] as Map)
              : dd;
          final tok = (dd['token'] ?? data['token'])?.toString();
          if (tok != null && tok.isNotEmpty) {
            DriverSession.authToken = tok;
          }
          final profile = UserProfile.fromJson(u);
          currentUser = profile;
          return profile;
        }
        final msg =
            (data is Map && (data['message'] != null || data['error'] != null))
            ? (data['message'] ?? data['error']).toString()
            : 'Login failed';
        throw Exception(msg);
      } catch (e) {
        if (e is FormatException) {
          final snippet = res3.body.substring(
            0,
            res3.body.length > 240 ? 240 : res3.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      if (res3.statusCode == 401) {
        throw Exception('Incorrect email or password');
      }
      final snippet = res3.body.substring(
        0,
        res3.body.length > 240 ? 240 : res3.body.length,
      );
      throw Exception('HTTP ' + res3.statusCode.toString() + ': ' + snippet);
    }
    return null;
  }

  static Future<List<Order>> fetchAvailableOrders() async {
    final publicUri = Uri.parse(ApiEndpoints.ordersPage);
    final publicRes = await http
        .get(publicUri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (publicRes.statusCode == 200) {
      try {
        final data = jsonDecode(publicRes.body);
        if (data is Map &&
            ((data['status'] == 'success' || data['success'] == true) &&
                (data['orders'] is List))) {
          final list = List<Map<String, dynamic>>.from(data['orders']);
          return list.map((e) {
            final first = (e['customer_first_name'] ?? '').toString();
            final last = (e['customer_last_name'] ?? '').toString();
            final name = (first + ' ' + last).trim();
            final payoutNum = (e['total_amount'] is num)
                ? (e['total_amount'] as num).toDouble()
                : double.tryParse((e['total_amount'] ?? '0').toString()) ?? 0.0;
            final lat = double.tryParse(
              (e['latitude'] ?? e['dealer_latitude'] ?? '').toString(),
            );
            final lng = double.tryParse(
              (e['longitude'] ?? e['dealer_longitude'] ?? '').toString(),
            );
            final phone =
                (e['delivery_phone'] ?? e['customer_phone'] ?? e['phone'] ?? '')
                    .toString();
            final food = _s(
              ((e['food_title'] ??
                      e['food_type'] ??
                      e['category'] ??
                      e['order_type'] ??
                      e['items_summary'] ??
                      '')
                  .toString()),
            );
            DateTime? created;
            final dstr =
                (e['order_date'] ??
                        e['created_at'] ??
                        e['order_date_formatted'] ??
                        '')
                    .toString();
            if (dstr.isNotEmpty) {
              try {
                created = DateTime.tryParse(dstr);
              } catch (_) {}
            }
            return Order(
              id: _s(e['order_id']?.toString()),
              customerName: _s(
                name.isEmpty ? (e['delivery_phone'] ?? '').toString() : name,
              ),
              customerPhone: _normalizePhone(phone),
              pickupAddress: _s(
                (e['dealer_address'] ?? e['business_address'] ?? '').toString(),
              ),
              deliveryAddress: _s((e['delivery_address'] ?? '').toString()),
              status: _s((e['status'] ?? 'confirmed').toString()),
              payout: payoutNum,
              dealerLat: lat,
              dealerLng: lng,
              foodType: food.isNotEmpty ? food : null,
              createdAt: created,
            );
          }).toList();
        }
      } catch (_) {}
    }
    return <Order>[];
  }

  static Future<bool> acceptOrder(
    String orderId, {
    double? proposedFee,
    DateTime? pickupTime,
  }) async {
    lastError = null;
    int? driverId = await resolveDriverId();
    try {
      await updateDriverAvailability(true);
    } catch (_) {}
    final uri = Uri.parse(
      ApiEndpoints.ordersPage,
    ).replace(queryParameters: {'action': 'accept'});
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'Authorization': 'Bearer ' + (DriverSession.authToken ?? ''),
    };
    final body = <String, String>{
      'order_id': orderId,
      'action': 'accept',
      if (driverId != null) 'driver_id': driverId.toString(),
      if (currentUser?.userId != null)
        'user_id': currentUser!.userId.toString(),
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
      if (proposedFee != null) 'delivery_fee': proposedFee.toString(),
      if (proposedFee != null) 'fee': proposedFee.toString(),
      if (pickupTime != null) 'pickup_time': pickupTime.toIso8601String(),
      if (pickupTime != null) 'pickup_at': pickupTime.toIso8601String(),
      'driver_assigned_at': nowTs(),
      'driver_assigned_time': nowTs(),
      'assigned_at': nowTs(),
      'driver_status': 'online',
      'available': '1',
      'online': '1',
      'is_driver': '1',
      'role': 'driver',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'token': (DriverSession.authToken ?? ''),
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'session_token': (DriverSession.authToken ?? ''),
    };
    http.Response? res;
    try {
      res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e.toString();
    }
    if (res != null && res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'success' ||
                data['accepted'] == true);
        if (ok) return true;
        if (data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
      } catch (_) {}
    }
    final alt1 = Uri.parse(
      ApiEndpoints.ordersPage,
    ).replace(queryParameters: {'action': 'accept'});
    final body1 = Map<String, String>.from(body)..['action'] = 'accept';
    http.Response? res1;
    try {
      res1 = await http
          .post(alt1, headers: headers, body: body1)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e.toString();
    }
    if (res1 != null && res1.statusCode == 200) {
      try {
        final data = jsonDecode(res1.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'success' ||
                data['accepted'] == true);
        if (ok) return true;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
      } catch (_) {}
    }
    final alt2 = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'accept'});
    http.Response? res2;
    try {
      res2 = await http
          .post(alt2, headers: headers, body: body1)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e.toString();
    }
    if (res2 != null && res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'success' ||
                data['accepted'] == true);
        if (ok) return true;
        if (data is Map && (data['message'] != null || data['error'] != null)) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
      } catch (_) {}
    } else if (res != null) {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      lastError = 'HTTP ${res.statusCode}: $snippet';
    }
    return false;
  }

  static Future<bool> rejectOrder(String orderId) async {
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'reject'});
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'order_id': orderId, 'action': 'reject'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        return data is Map &&
            (data['success'] == true ||
                data['status'] == 'rejected' ||
                data['status'] == 'success');
      } catch (_) {}
    }
    return false;
  }

  static Future<List<Order>> fetchMyOrders() async {
    final driverId = await resolveDriverId();
    if (driverId == null) return <Order>[];
    final uri = Uri.parse(
      ApiEndpoints.driverAvailable,
    ).replace(queryParameters: {'driver_id': driverId.toString()});
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map &&
            ((data['status'] == 'success') &&
                (data['assignments'] is List || data['orders'] is List))) {
          final list = (data['assignments'] is List)
              ? List<Map<String, dynamic>>.from(data['assignments'])
              : (data['orders'] is List)
              ? List<Map<String, dynamic>>.from(data['orders'])
              : <Map<String, dynamic>>[];
          return list.map((e) {
            final first = (e['customer_first_name'] ?? '').toString();
            final last = (e['customer_last_name'] ?? '').toString();
            final name = (first + ' ' + last).trim();
            final payoutNum = (e['total_amount'] is num)
                ? (e['total_amount'] as num).toDouble()
                : double.tryParse((e['total_amount'] ?? '0').toString()) ?? 0.0;
            final phone =
                (e['delivery_phone'] ?? e['customer_phone'] ?? e['phone'] ?? '')
                    .toString();
            final food = _s(
              ((e['food_title'] ??
                      e['food_type'] ??
                      e['category'] ??
                      e['order_type'] ??
                      e['items_summary'] ??
                      '')
                  .toString()),
            );
            return Order(
              id: _s(e['order_id']?.toString()),
              customerName: _s(
                name.isEmpty ? (e['delivery_phone'] ?? '').toString() : name,
              ),
              customerPhone: _normalizePhone(phone),
              pickupAddress: _s((e['dealer_address'] ?? '').toString()),
              deliveryAddress: _s((e['delivery_address'] ?? '').toString()),
              status: _s((e['status'] ?? 'confirmed').toString()),
              payout: payoutNum,
              foodType: food.isNotEmpty ? food : null,
            );
          }).toList();
        }
      } catch (_) {}
    }
    return <Order>[];
  }

  static Future<bool> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty) return false;
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'update_location'});
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        return data is Map && data['success'] == true;
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> updateDriverAvailability(bool online) async {
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty && currentUser?.userId == null) return false;
    final uri = Uri.parse(
      ApiEndpoints.drivers,
    ).replace(queryParameters: {'action': 'update_availability'});
    final body = {
      if (currentUser?.userId != null)
        'user_id': currentUser!.userId.toString(),
      if (currentUser?.driverId != null)
        'driver_id': currentUser!.driverId!.toString(),
      'status': online ? 'online' : 'offline',
      'available': online ? '1' : '0',
      'online': online ? '1' : '0',
    };
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': token.isNotEmpty ? 'Bearer ' + token : '',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        return data is Map &&
            (data['success'] == true || data['status'] == 'success');
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? action,
    Map<String, dynamic>? extra,
  }) async {
    final driverId = await resolveDriverId();
    final uri = Uri.parse(
      ApiEndpoints.ordersPage,
    ).replace(queryParameters: {'action': action ?? 'update_status'});
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'Authorization': 'Bearer ' + (DriverSession.authToken ?? ''),
    };
    final body = <String, String>{
      'order_id': orderId,
      'status': status,
      'action': action ?? 'update_status',
      if (currentUser?.userId != null)
        'user_id': currentUser!.userId.toString(),
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
      if (driverId != null) 'driver_id': driverId.toString(),
      'is_driver': '1',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'token': (DriverSession.authToken ?? ''),
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'session_token': (DriverSession.authToken ?? ''),
      if (extra != null) ...extra.map((k, v) => MapEntry(k, v.toString())),
    };
    http.Response? res;
    try {
      res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e.toString();
    }
    if (res != null && res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        final ok =
            data is Map &&
            (data['success'] == true || data['status'] == 'success');
        if (!ok && data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
        return ok;
      } catch (e) {
        lastError = e.toString();
      }
    }
    if (res != null) {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      lastError = 'HTTP ${res.statusCode}: $snippet';
    }
    return false;
  }

  static Future<bool> _postStatusToDriverOrders(
    String orderId,
    String status, {
    String? action,
    Map<String, dynamic>? extra,
  }) async {
    final driverId = await resolveDriverId();
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': action ?? 'update_status'});
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'Authorization': 'Bearer ' + (DriverSession.authToken ?? ''),
    };
    final body = <String, String>{
      'order_id': orderId,
      'status': status,
      'action': action ?? 'update_status',
      if (currentUser?.userId != null)
        'user_id': currentUser!.userId.toString(),
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
      if (driverId != null) 'driver_id': driverId.toString(),
      'is_driver': '1',
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'token': (DriverSession.authToken ?? ''),
      if ((DriverSession.authToken ?? '').isNotEmpty)
        'session_token': (DriverSession.authToken ?? ''),
      if (extra != null) ...extra.map((k, v) => MapEntry(k, v.toString())),
    };
    http.Response? res;
    try {
      res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e.toString();
    }
    if (res != null && res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        final ok =
            data is Map &&
            (data['success'] == true || data['status'] == 'success');
        if (!ok && data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
        return ok;
      } catch (e) {
        lastError = e.toString();
      }
    }
    if (res != null) {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      lastError = 'HTTP ${res.statusCode}: $snippet';
    }
    return false;
  }

  static Future<bool> markDelivered(String orderId, {double? fee}) async {
    final ts = nowTs();
    final dId = await resolveDriverId();
    final extra = <String, dynamic>{
      'driver_delivered_time': ts,
      'driver_delivery_time': ts,
      'delivered_at': ts,
      if (fee != null) 'delivery_fee': fee,
      if (fee != null) 'fee': fee,
      if (dId != null) 'driver_id': dId,
      if (currentUser?.userId != null) 'user_id': currentUser!.userId!,
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
    };
    bool ok = await updateOrderStatus(
      orderId,
      'delivered',
      action: 'update_status',
      extra: extra,
    );
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'delivered',
        action: 'deliver',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'delivered',
        action: 'deliver',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'delivered',
        action: 'update_status',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'completed',
        action: 'update_status',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'completed',
        action: 'complete',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'completed',
        action: 'update_status',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'completed',
        action: 'complete',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (ok) {
      try {
        DriverSession.lastDeliveredAt = DateTime.now();
      } catch (_) {}
    }
    return ok;
  }

  static Future<bool> markDeliveredOrdersPhp(
    String orderId, {
    double? fee,
  }) async {
    final ts = nowTs();
    final dId = await resolveDriverId();
    final extra = <String, dynamic>{
      'driver_delivered_time': ts,
      'driver_delivery_time': ts,
      'delivered_at': ts,
      if (fee != null) 'delivery_fee': fee,
      if (fee != null) 'fee': fee,
      if (dId != null) 'driver_id': dId,
      if (currentUser?.userId != null) 'user_id': currentUser!.userId!,
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
    };
    bool ok = await updateOrderStatus(
      orderId,
      'delivered',
      action: 'deliver',
      extra: extra,
    );
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'delivered',
        action: 'update_status',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'completed',
        action: 'complete',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'completed',
        action: 'update_status',
        extra: {...extra, 'driver_completed_time': ts, 'completed_at': ts},
      );
    }
    if (ok) {
      try {
        DriverSession.lastDeliveredAt = DateTime.now();
      } catch (_) {}
    }
    return ok;
  }

  static Future<bool> cancelOrder(String orderId) async {
    final ts = nowTs();
    final dId = await resolveDriverId();
    final extra = <String, dynamic>{
      'driver_canceled_time': ts,
      'canceled_at': ts,
      if (dId != null) 'driver_id': dId,
      if (currentUser?.userId != null) 'user_id': currentUser!.userId!,
      if (currentUser?.username.isNotEmpty == true)
        'driver': currentUser!.username,
    };
    bool ok = await updateOrderStatus(
      orderId,
      'awaiting',
      action: 'update_status',
      extra: extra,
    );
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'awaiting',
        action: 'cancel',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'awaiting',
        action: 'reject',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'awaiting',
        action: 'update_status',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'awaiting',
        action: 'cancel',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'cancelled',
        action: 'update_status',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await updateOrderStatus(
        orderId,
        'cancelled',
        action: 'cancel',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'cancelled',
        action: 'update_status',
        extra: extra,
      );
    }
    if (!ok) {
      ok = await _postStatusToDriverOrders(
        orderId,
        'cancelled',
        action: 'cancel',
        extra: extra,
      );
    }
    return ok;
  }

  static Future<bool> openOrdersPage() async {
    final url = Uri.parse(ApiEndpoints.ordersPage);
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> signup(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse(
      ApiEndpoints.drivers,
    ).replace(queryParameters: {'action': 'signup'});
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Signup failed');
      } catch (e) {
        if (e is FormatException) {
          final snippet = res.body.substring(
            0,
            res.body.length > 240 ? 240 : res.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      throw Exception('HTTP ${res.statusCode}: $snippet');
    }
    final alt = Uri.parse(
      'https://' + apiHost + '/drivers/driver_api.php',
    ).replace(queryParameters: {'action': 'signup'});
    final res2 = await http
        .post(
          alt,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {
            ...payload.map((k, v) => MapEntry(k, v.toString())),
            'action': 'signup',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Signup failed');
      } catch (e) {
        if (e is FormatException) {
          final snippet = res2.body.substring(
            0,
            res2.body.length > 240 ? 240 : res2.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      final snippet = res2.body.substring(
        0,
        res2.body.length > 240 ? 240 : res2.body.length,
      );
      throw Exception('HTTP ${res2.statusCode}: $snippet');
    }
    final formHeaders = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };
    final formBody = payload.map((k, v) => MapEntry(k, v.toString()));
    final res3 = await http
        .post(uri, headers: formHeaders, body: formBody)
        .timeout(const Duration(seconds: 12));
    if (res3.statusCode == 200) {
      try {
        final data = jsonDecode(res3.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Signup failed');
      } catch (e) {
        if (e is FormatException) {
          final snippet = res3.body.substring(
            0,
            res3.body.length > 240 ? 240 : res3.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      final snippet = res3.body.substring(
        0,
        res3.body.length > 240 ? 240 : res3.body.length,
      );
      throw Exception('HTTP ${res3.statusCode}: $snippet');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> signupMultipart(
    Map<String, dynamic> payload,
    String? photoPath,
  ) async {
    final uri = Uri.parse(
      ApiEndpoints.drivers,
    ).replace(queryParameters: {'action': 'signup'});
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    payload.forEach((k, v) => req.fields[k] = v.toString());
    final lat = payload['latitude']?.toString();
    final lng = payload['longitude']?.toString();
    if (lat != null && lat.isNotEmpty) {
      req.fields['current_latitude'] = lat;
    }
    if (lng != null && lng.isNotEmpty) {
      req.fields['current_longitude'] = lng;
    }
    req.fields['action'] = 'signup';
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final file = await http.MultipartFile.fromPath('photo', photoPath);
        req.files.add(file);
      } catch (_) {}
    }
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Signup failed');
      } catch (e) {
        if (e is FormatException) {
          final snippet = res.body.substring(
            0,
            res.body.length > 240 ? 240 : res.body.length,
          );
          throw Exception('Invalid JSON response: $snippet');
        }
      }
    } else {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      throw Exception('HTTP ${res.statusCode}: $snippet');
    }
    return null;
  }

  static Future<List<Order>> fetchOrders(int driverId) async {
    final uri = Uri.parse(ApiEndpoints.orders);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'driver_id': driverId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true) {
        final list = (data['data'] is Map && data['data']['orders'] is List)
            ? List<Map<String, dynamic>>.from(data['data']['orders'])
            : <Map<String, dynamic>>[];
        return list.map((e) {
          final customer = (e['customer'] is Map)
              ? Map<String, dynamic>.from(e['customer'] as Map)
              : <String, dynamic>{};
          final dealer = (e['dealer'] is Map)
              ? Map<String, dynamic>.from(e['dealer'] as Map)
              : <String, dynamic>{};
          final details = (e['order_details'] is Map)
              ? Map<String, dynamic>.from(e['order_details'] as Map)
              : <String, dynamic>{};
          final first = (customer['first_name'] ?? '').toString();
          final last = (customer['last_name'] ?? '').toString();
          final name = (first + ' ' + last).trim();
          final payoutNum = (details['total_amount'] is num)
              ? (details['total_amount'] as num).toDouble()
              : double.tryParse((details['total_amount'] ?? '0').toString()) ??
                    0.0;
          final phone =
              (customer['phone'] ??
                      details['delivery_phone'] ??
                      details['phone'] ??
                      '')
                  .toString();
          final food = _s(
            ((details['food_type'] ??
                    details['category'] ??
                    details['order_type'] ??
                    details['items_summary'] ??
                    '')
                .toString()),
          );
          DateTime? created;
          final dstr =
              (details['order_date'] ??
                      details['created_at'] ??
                      e['created_at'] ??
                      '')
                  .toString();
          if (dstr.isNotEmpty) {
            try {
              created = DateTime.tryParse(dstr);
            } catch (_) {}
          }
          return Order(
            id: _s((e['order_id'] ?? '').toString()),
            customerName: _s(
              name.isEmpty ? (customer['email'] ?? '').toString() : name,
            ),
            customerPhone: _normalizePhone(phone),
            pickupAddress: _s((dealer['business_address'] ?? '').toString()),
            deliveryAddress: _s((details['delivery_address'] ?? '').toString()),
            status: _s((details['status'] ?? 'awaiting').toString()),
            payout: payoutNum,
            foodType: food.isNotEmpty ? food : null,
            createdAt: created,
          );
        }).toList();
      }
    }
    return <Order>[];
  }

  static Future<Map<String, num>?> fetchDashboard(int driverId) async {
    final uri = Uri.parse(ApiEndpoints.dashboard);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'driver_id': driverId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true) {
        final d = Map<String, dynamic>.from(data['data'] as Map);
        return {
          'total_earnings': (d['total_earnings'] as num?) ?? 0,
          'deliveries_count': (d['deliveries_count'] as num?) ?? 0,
          'active_orders': (d['active_orders'] as num?) ?? 0,
        };
      }
    }
    return null;
  }

  static Future<List<DeliveryHistory>> fetchEarnings(int driverId) async {
    final uri = Uri.parse(ApiEndpoints.earnings);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'driver_id': driverId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true) {
        final list = (data['data'] is Map && data['data']['history'] is List)
            ? List<Map<String, dynamic>>.from(data['data']['history'])
            : <Map<String, dynamic>>[];
        return list
            .map(
              (e) => DeliveryHistory(
                id: _s((e['id'] ?? e['order_id'] ?? '').toString()),
                date: _s((e['date'] ?? e['created_at'] ?? '').toString()),
                summary: _s(
                  (e['summary'] ?? e['description'] ?? '').toString(),
                ),
                amount:
                    double.tryParse(
                      (e['amount'] ?? e['payout'] ?? '0').toString(),
                    ) ??
                    0.0,
              ),
            )
            .toList();
      }
    }
    return <DeliveryHistory>[];
  }

  static Future<Map<String, dynamic>?> fetchDriverAssignmentsAndStats(
    int driverId,
  ) async {
    final uri = Uri.parse(
      ApiEndpoints.ordersPage,
    ).replace(queryParameters: {'driver_id': driverId.toString()});
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map &&
          (data['status'] == 'success' || data['success'] == true)) {
        final d = Map<String, dynamic>.from(data);
        final stats = (d['statistics'] is Map)
            ? Map<String, dynamic>.from(d['statistics'] as Map)
            : <String, dynamic>{};
        final active = (d['active_orders'] is List)
            ? List<Map<String, dynamic>>.from(d['active_orders'] as List)
            : <Map<String, dynamic>>[];
        final completed = (d['completed_orders'] is List)
            ? List<Map<String, dynamic>>.from(d['completed_orders'] as List)
            : <Map<String, dynamic>>[];
        List<DeliveryHistory> toHist(
          List<Map<String, dynamic>> list, {
          required bool delivered,
        }) {
          return list.map((e) {
            final id = _s(
              ((e['order_id'] ?? e['booking_id'] ?? '').toString().isNotEmpty)
                  ? (e['order_id'] ?? e['booking_id']).toString()
                  : (e['booking_id'] != null
                        ? ('B' + e['booking_id'].toString())
                        : ''),
            );
            final date = _s(
              (e['driver_assigned_at'] ??
                      e['order_date'] ??
                      e['order_date_formatted'] ??
                      e['updated_at'] ??
                      '')
                  .toString(),
            );
            final addr = _s(
              (e['delivery_address'] ?? e['business_address'] ?? '').toString(),
            );
            final first = _s((e['customer_first_name'] ?? '').toString());
            final last = _s((e['customer_last_name'] ?? '').toString());
            final fallback = _s(
              (e['customer_email'] ?? e['customer_phone'] ?? '').toString(),
            );
            final name = ((first + ' ' + last).trim().isEmpty)
                ? fallback
                : (first + ' ' + last).trim();
            final summary = delivered
                ? ('Delivered: ' + addr)
                : ('Accepted: ' + addr);
            final amount =
                double.tryParse(
                  ((e['driver_earnings'] ?? e['delivery_fee'] ?? '0'))
                      .toString(),
                ) ??
                0.0;
            return DeliveryHistory(
              id: id,
              date: date,
              summary: summary,
              amount: amount,
              customerName: name,
              address: addr,
            );
          }).toList();
        }

        final accepted = toHist(active, delivered: false);
        final deliveredList = toHist(completed, delivered: true);
        final total = (stats['estimated_earnings'] is num)
            ? (stats['estimated_earnings'] as num).toDouble()
            : double.tryParse(
                    (stats['estimated_earnings'] ?? '0').toString(),
                  ) ??
                  0.0;
        return {
          'accepted': accepted,
          'delivered': deliveredList,
          'total': total,
        };
      }
    }
    return null;
  }

  static Future<Order?> fetchOrderDetails(dynamic orderId) async {
    final uri = Uri.parse(ApiEndpoints.orderDetails);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'order_id': orderId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true) {
        final o = (data['data'] is Map && data['data']['order'] is Map)
            ? Map<String, dynamic>.from(data['data']['order'] as Map)
            : <String, dynamic>{};
        return Order(
          id: _s((o['order_id'] ?? o['id'] ?? '').toString()),
          customerName: _s((o['customer_name'] ?? '').toString()),
          customerPhone: _normalizePhone(
            (o['customer_phone'] ?? o['delivery_phone'] ?? o['phone'] ?? '')
                ?.toString(),
          ),
          pickupAddress: _s((o['pickup_address'] ?? '').toString()),
          deliveryAddress: _s((o['delivery_address'] ?? '').toString()),
          status: _s((o['status'] ?? 'awaiting').toString()),
          payout: double.tryParse((o['payout'] ?? '0').toString()) ?? 0.0,
        );
      }
    }
    return null;
  }

  static Future<Order?> fetchOrderDetailsFromOrdersPage(dynamic orderId) async {
    final uri = Uri.parse(
      ApiEndpoints.ordersPage,
    ).replace(queryParameters: {'order_id': orderId.toString()});
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        Map<String, dynamic>? o;
        if (data is Map) {
          if (data['order'] is Map) {
            o = Map<String, dynamic>.from(data['order'] as Map);
          } else if (data['data'] is Map &&
              (data['data'] as Map)['order'] is Map) {
            o = Map<String, dynamic>.from(
              (data['data'] as Map)['order'] as Map,
            );
          } else if (data['orders'] is List) {
            final list = List<Map<String, dynamic>>.from(data['orders']);
            o = list.firstWhere(
              (e) =>
                  ((e['order_id'] ?? e['id'] ?? '').toString()) ==
                  orderId.toString(),
              orElse: () => <String, dynamic>{},
            );
          }
        }
        if (o != null && o.isNotEmpty) {
          final first = (o['customer_first_name'] ?? '').toString();
          final last = (o['customer_last_name'] ?? '').toString();
          final nameRaw = (first + ' ' + last).trim();
          final name = nameRaw.isNotEmpty
              ? nameRaw
              : (o['customer_name'] ?? '').toString();
          final payoutNum = (o['total_amount'] is num)
              ? (o['total_amount'] as num).toDouble()
              : double.tryParse((o['total_amount'] ?? '0').toString()) ?? 0.0;
          final phone =
              (o['delivery_phone'] ?? o['customer_phone'] ?? o['phone'] ?? '')
                  .toString();
          final lat = double.tryParse(
            (o['latitude'] ?? o['dealer_latitude'] ?? '').toString(),
          );
          final lng = double.tryParse(
            (o['longitude'] ?? o['dealer_longitude'] ?? '').toString(),
          );
          return Order(
            id: _s((o['order_id'] ?? o['id'] ?? '').toString()),
            customerName: _s(
              name.isNotEmpty ? name : (o['customer_email'] ?? '').toString(),
            ),
            customerPhone: _normalizePhone(phone),
            pickupAddress: _s(
              (o['dealer_address'] ?? o['business_address'] ?? '').toString(),
            ),
            deliveryAddress: _s((o['delivery_address'] ?? '').toString()),
            status: _s((o['status'] ?? 'awaiting').toString()),
            payout: payoutNum,
            dealerLat: lat,
            dealerLng: lng,
          );
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<UserProfile?> fetchProfile(int userId) async {
    final uri = Uri.parse(ApiEndpoints.profile);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true) {
        final dd = Map<String, dynamic>.from(data['data'] as Map);
        final u = dd['user'] is Map
            ? Map<String, dynamic>.from(dd['user'] as Map)
            : dd;
        return UserProfile.fromJson(u);
      }
    }
    return null;
  }

  static Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final uri = Uri.parse(ApiEndpoints.changePassword);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is Map && data['success'] == true;
    }
    return false;
  }
}
