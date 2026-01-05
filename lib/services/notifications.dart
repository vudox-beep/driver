import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _inited = true;
    await ensurePermissions();
  }

  static Future<void> ensurePermissions() async {
    if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
    }
  }

  static Future<void> showNewOrder(String id, String title, String body) async {
    if (!_inited) await init();
    const androidDetails = AndroidNotificationDetails(
      'orders_channel',
      'Orders',
      channelDescription: 'New and updated orders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id.hashCode, title, body, details);
  }
}
