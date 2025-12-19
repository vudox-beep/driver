import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class ApiClient {
  static String? lastError;
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
    return c;
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
          return UserProfile.fromJson(u);
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
          throw Exception('Invalid JSON response: ' + snippet);
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
      throw Exception('HTTP ' + res.statusCode.toString() + ': ' + snippet);
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
          return UserProfile.fromJson(u);
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
          throw Exception('Invalid JSON response: ' + snippet);
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
          return UserProfile.fromJson(u);
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
          throw Exception('Invalid JSON response: ' + snippet);
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
            return Order(
              id: _s(e['order_id']?.toString()),
              customerName: _s(
                name.isEmpty ? (e['delivery_phone'] ?? '').toString() : name,
              ),
              pickupAddress: _s(
                (e['dealer_address'] ?? e['business_address'] ?? '').toString(),
              ),
              deliveryAddress: _s((e['delivery_address'] ?? '').toString()),
              status: _s((e['status'] ?? 'confirmed').toString()),
              payout: payoutNum,
              dealerLat: lat,
              dealerLng: lng,
            );
          }).toList();
        }
      } catch (_) {}
    }
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty) return <Order>[];
    final uri = Uri.parse(ApiEndpoints.driverAvailable);
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map &&
            ((data['success'] == true || data['status'] == 'success') &&
                (data['orders'] is List || data['data'] is List))) {
          final list = (data['orders'] is List)
              ? List<Map<String, dynamic>>.from(data['orders'])
              : (data['data'] is List)
              ? List<Map<String, dynamic>>.from(data['data'])
              : <Map<String, dynamic>>[];
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
            return Order(
              id: _s(e['order_id']?.toString()),
              customerName: _s(
                name.isEmpty ? (e['delivery_phone'] ?? '').toString() : name,
              ),
              pickupAddress: _s(
                (e['dealer_address'] ?? e['business_address'] ?? '').toString(),
              ),
              deliveryAddress: _s((e['delivery_address'] ?? '').toString()),
              status: _s((e['status'] ?? 'confirmed').toString()),
              payout: payoutNum,
              dealerLat: lat,
              dealerLng: lng,
            );
          }).toList();
        }
      } catch (_) {}
    }
    final alt = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'available_orders'});
    final res2 = await http
        .get(
          alt,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        if (data is Map &&
            (data['success'] == true || data['orders'] is List)) {
          final list = (data['orders'] is List)
              ? List<Map<String, dynamic>>.from(data['orders'])
              : (data['data'] is List)
              ? List<Map<String, dynamic>>.from(data['data'])
              : <Map<String, dynamic>>[];
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
            return Order(
              id: (e['order_id'] ?? '').toString(),
              customerName: name.isEmpty
                  ? (e['delivery_phone'] ?? '').toString()
                  : name,
              pickupAddress:
                  (e['dealer_address'] ?? e['business_address'] ?? '')
                      .toString(),
              deliveryAddress: (e['delivery_address'] ?? '').toString(),
              status: (e['status'] ?? 'confirmed').toString(),
              payout: payoutNum,
              dealerLat: lat,
              dealerLng: lng,
            );
          }).toList();
        }
      } catch (_) {}
    }
    return <Order>[];
  }

  static Future<bool> acceptOrder(String orderId) async {
    lastError = null;
    final driverId = currentUser?.driverId;
    if (driverId != null) {
      final availableUri = Uri.parse(ApiEndpoints.driverAvailable);
      final resAvail = await http
          .post(
            availableUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'driver_id': driverId,
              'order_id': int.tryParse(orderId) ?? orderId,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (resAvail.statusCode == 200) {
        try {
          final data = jsonDecode(resAvail.body);
          final ok =
              data is Map &&
              (data['status'] == 'success' ||
                  data['accepted'] == true ||
                  data['success'] == true);
          if (ok) return true;
        } catch (_) {}
      }
    }
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty) return false;
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'accept_order'});
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'order_id': int.tryParse(orderId) ?? orderId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'accepted' ||
                data['status'] == 'success');
        if (!ok && data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
        return ok;
      } catch (_) {}
    }
    final resForm = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'order_id': orderId, 'action': 'accept_order'},
        )
        .timeout(const Duration(seconds: 12));
    if (resForm.statusCode == 200) {
      try {
        final data = jsonDecode(resForm.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'accepted' ||
                data['status'] == 'success');
        if (!ok && data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
        return ok;
      } catch (_) {}
    }
    final alt = Uri.parse(
      'https://' + apiHost + '/drivers/driver_orders.php',
    ).replace(queryParameters: {'action': 'accept_order'});
    final res2 = await http
        .post(
          alt,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'order_id': int.tryParse(orderId) ?? orderId}),
        )
        .timeout(const Duration(seconds: 12));
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        final ok =
            data is Map &&
            (data['success'] == true ||
                data['status'] == 'accepted' ||
                data['status'] == 'success');
        if (!ok && data is Map) {
          lastError = (data['message'] ?? data['error'] ?? '').toString();
        }
        return ok;
      } catch (_) {}
    }
    if (driverId != null) {
      final alt2 = Uri.parse(ApiEndpoints.driverAvailable);
      final res3 = await http
          .post(
            alt2,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'driver_id': driverId,
              'order_id': int.tryParse(orderId) ?? orderId,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res3.statusCode == 200) {
        try {
          final data = jsonDecode(res3.body);
          final ok =
              data is Map &&
              (data['status'] == 'success' || data['accepted'] == true);
          if (!ok && data is Map) {
            lastError = (data['message'] ?? data['error'] ?? '').toString();
          }
          return ok;
        } catch (_) {}
      }
    }
    return false;
  }

  static Future<bool> rejectOrder(String orderId) async {
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty) return false;
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'reject'});
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ' + token,
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
    final alt = Uri.parse(
      'https://' + apiHost + '/drivers/driver_orders.php',
    ).replace(queryParameters: {'action': 'reject'});
    final res2 = await http
        .post(
          alt,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'order_id': orderId, 'action': 'reject'},
        )
        .timeout(const Duration(seconds: 12));
    if (res2.statusCode == 200) {
      try {
        final data = jsonDecode(res2.body);
        return data is Map &&
            (data['success'] == true ||
                data['status'] == 'rejected' ||
                data['status'] == 'success');
      } catch (_) {}
    }
    return false;
  }

  static Future<List<Order>> fetchMyOrders() async {
    final driverId = currentUser?.driverId;
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
            return Order(
              id: _s(e['order_id']?.toString()),
              customerName: _s(
                name.isEmpty ? (e['delivery_phone'] ?? '').toString() : name,
              ),
              pickupAddress: _s((e['dealer_address'] ?? '').toString()),
              deliveryAddress: _s((e['delivery_address'] ?? '').toString()),
              status: _s((e['status'] ?? 'confirmed').toString()),
              payout: payoutNum,
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

  static Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? action,
  }) async {
    final token = DriverSession.authToken ?? '';
    if (token.isEmpty) return false;
    final uri = Uri.parse(
      ApiEndpoints.driverOrders,
    ).replace(queryParameters: {'action': 'update_status'});
    final res = await http
        .put(
          uri,
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'order_id': int.tryParse(orderId) ?? orderId,
            'status': status,
            if (action != null) 'action': action,
          }),
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
          throw Exception('Invalid JSON response: ' + snippet);
        }
      }
    } else {
      final snippet = res.body.substring(
        0,
        res.body.length > 240 ? 240 : res.body.length,
      );
      throw Exception('HTTP ' + res.statusCode.toString() + ': ' + snippet);
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
          throw Exception('Invalid JSON response: ' + snippet);
        }
      }
    } else {
      final snippet = res2.body.substring(
        0,
        res2.body.length > 240 ? 240 : res2.body.length,
      );
      throw Exception('HTTP ' + res2.statusCode.toString() + ': ' + snippet);
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
          throw Exception('Invalid JSON response: ' + snippet);
        }
      }
    } else {
      final snippet = res3.body.substring(
        0,
        res3.body.length > 240 ? 240 : res3.body.length,
      );
      throw Exception('HTTP ' + res3.statusCode.toString() + ': ' + snippet);
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
          return Order(
            id: _s((e['order_id'] ?? '').toString()),
            customerName: _s(
              name.isEmpty ? (customer['email'] ?? '').toString() : name,
            ),
            pickupAddress: _s((dealer['business_address'] ?? '').toString()),
            deliveryAddress: _s((details['delivery_address'] ?? '').toString()),
            status: _s((details['status'] ?? 'awaiting').toString()),
            payout: payoutNum,
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
          pickupAddress: _s((o['pickup_address'] ?? '').toString()),
          deliveryAddress: _s((o['delivery_address'] ?? '').toString()),
          status: _s((o['status'] ?? 'awaiting').toString()),
          payout: double.tryParse((o['payout'] ?? '0').toString()) ?? 0.0,
        );
      }
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
