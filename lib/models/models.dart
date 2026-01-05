import 'package:flutter/services.dart';

class Order {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String status;
  final double payout;
  final double? dealerLat;
  final double? dealerLng;
  final double? distanceKm;
  final String? foodType;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.payout,
    this.dealerLat,
    this.dealerLng,
    this.distanceKm,
    this.foodType,
    this.createdAt,
  });
}

class DeliveryHistory {
  final String id;
  final String date;
  final String summary;
  final double amount;
  final String? customerName;
  final String? address;

  const DeliveryHistory({
    required this.id,
    required this.date,
    required this.summary,
    required this.amount,
    this.customerName,
    this.address,
  });
}

class UserProfile {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final int? driverId;
  final String? driverStatus;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? licenseNumber;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.driverId,
    this.driverStatus,
    this.vehicleType,
    this.vehiclePlate,
    this.licenseNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String s(String? v) {
      final str = (v ?? '').toString();
      final a = str.replaceAll(RegExp(r"<[^>]*>"), '');
      final b = a
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"');
      return b.replaceAll(RegExp(r"\s+"), ' ').trim();
    }

    return UserProfile(
      userId: (json['user_id'] ?? json['id']) is String
          ? int.tryParse(json['user_id'] ?? json['id']) ?? 0
          : (json['user_id'] ?? json['id'] ?? 0) as int,
      username: s(json['username']),
      email: s(json['email']),
      firstName: s(json['first_name']),
      lastName: s(json['last_name']),
      phone: s(json['phone']),
      driverId: json['driver_id'] is String
          ? int.tryParse(json['driver_id'])
          : (json['driver_id'] as int?),
      driverStatus: s((json['driver_status'] ?? json['status'])?.toString()),
      vehicleType: s((json['vehicle_type'] ?? '')?.toString()),
      vehiclePlate: s((json['vehicle_plate'] ?? '')?.toString()),
      licenseNumber: s((json['license_number'] ?? '')?.toString()),
    );
  }
}

UserProfile? currentUser;

String apiHost = 'redtags.co.za';
String apiBase(String file) => 'https://' + apiHost + '/drivers/' + file;

class ApiEndpoints {
  static String get base => 'https://' + apiHost + '/drivers/';
  static String get drivers => base + 'driver_api.php';
  static String get driverOrders => base + 'orders_api.php';
  static String get driverAvailable => base + 'driver_available_orders.php';
  static String get orders => base + 'orders_api.php';
  static String get ordersPage => base + 'orders.php';
  static String get dashboard => base + 'dashboard_api.php';
  static String get earnings => base + 'earnings_api.php';
  static String get orderDetails => base + 'order_details_api.php';
  static String get profile => base + 'profile_api.php';
  static String get changePassword => base + 'change_password_api.php';
}

class DriverUser {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final int? driverId;
  final String? driverStatus;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? licenseNumber;

  const DriverUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.driverId,
    this.driverStatus,
    this.vehicleType,
    this.vehiclePlate,
    this.licenseNumber,
  });

  factory DriverUser.fromJson(Map<dynamic, dynamic> json) {
    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is num) return v.toInt();
      return null;
    }

    String s(String? v) {
      final str = (v ?? '').toString();
      final a = str.replaceAll(RegExp(r"<[^>]*>"), '');
      final b = a
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"');
      return b.replaceAll(RegExp(r"\s+"), ' ').trim();
    }

    return DriverUser(
      userId: toInt(json['user_id']) ?? toInt(json['id']) ?? 0,
      username: s(json['username']),
      email: s(json['email']),
      firstName: s(json['first_name']),
      lastName: s(json['last_name']),
      phone: s(json['phone']),
      driverId: toInt(json['driver_id']),
      driverStatus: s((json['driver_status'] ?? json['status'])?.toString()),
      vehicleType: s((json['vehicle_type'] ?? '').toString()),
      vehiclePlate: s((json['vehicle_plate'] ?? '').toString()),
      licenseNumber: s((json['license_number'] ?? '').toString()),
    );
  }
}

class DriverSession {
  static String apiHost = 'redtags.co.za';
  static DriverUser? currentUser;
  static String get apiBaseUrl =>
      'https://' + apiHost + '/drivers/driver_api.php';
  static String? authToken;
  static String mapboxToken = '';
  static String googleMapsApiKey = const String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static DateTime? lastDeliveredAt;
}

class AppMeta {
  static const _ch = MethodChannel('com.example.driver/app_meta');
  static Future<String> googleApiKey() async {
    try {
      final v = await _ch.invokeMethod<String>('getGoogleMapsApiKey');
      return (v ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static Future<void> ensureGoogleApiKeyLoaded() async {
    if (DriverSession.googleMapsApiKey.isNotEmpty) return;
    final v = await googleApiKey();
    if (v.isNotEmpty) {
      DriverSession.googleMapsApiKey = v;
    }
  }

  static Map<String, String>? _identity;
  static Future<Map<String, String>> androidIdentity() async {
    if (_identity != null) return _identity!;
    try {
      final v = await _ch.invokeMethod<Map<dynamic, dynamic>>(
        'getAndroidAppIdentity',
      );
      final pkg = (v?['package'] ?? '').toString();
      final sha1 = (v?['sha1'] ?? '').toString();
      _identity = {'package': pkg, 'sha1': sha1};
      return _identity!;
    } catch (_) {
      _identity = {'package': 'com.example.driver', 'sha1': ''};
      return _identity!;
    }
  }

  static Future<Map<String, String>> androidAuthHeaders() async {
    final id = await androidIdentity();
    final pkg = (id['package'] ?? '').trim();
    final sha1 = (id['sha1'] ?? '').trim();
    final h = <String, String>{};
    if (pkg.isNotEmpty) h['X-Android-Package'] = pkg;
    if (sha1.isNotEmpty) h['X-Android-Cert'] = sha1;
    return h;
  }
}
