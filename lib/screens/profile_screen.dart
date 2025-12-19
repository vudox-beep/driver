import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool available = true;
  bool notifications = true;
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool changingPassword = false;
  String? changeError;

  Future<void> fetchProfile() async {
    if (currentUser?.userId == 0) return;
    try {
      final uri = Uri.parse(ApiEndpoints.profile);
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': currentUser!.userId}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && (data['success'] == true)) {
          Map<String, dynamic> u;
          final dd = Map<String, dynamic>.from(data['data'] as Map);
          u = dd['user'] is Map
              ? Map<String, dynamic>.from(dd['user'] as Map)
              : dd;
          setState(() {
            currentUser = UserProfile.fromJson(u);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> changePassword() async {
    if (changingPassword) return;
    final oldP = oldPasswordController.text;
    final newP = newPasswordController.text;
    final confP = confirmPasswordController.text;
    if (newP.isEmpty || newP.length < 6 || newP != confP) {
      setState(() => changeError = 'Check passwords: minimum 6 and must match');
      return;
    }
    setState(() {
      changingPassword = true;
      changeError = null;
    });
    try {
      final uri = Uri.parse(ApiEndpoints.changePassword);
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': currentUser?.userId ?? 0,
              'old_password': oldP,
              'new_password': newP,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final ok =
          res.statusCode == 200 &&
          (() {
            try {
              final d = jsonDecode(res.body);
              return d is Map && d['success'] == true;
            } catch (_) {
              return false;
            }
          })();
      if (ok) {
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated')));
      } else {
        setState(
          () => changeError = res.body.isNotEmpty
              ? res.body
              : 'Failed to update password',
        );
      }
    } catch (_) {
      setState(() => changeError = 'Network error');
    } finally {
      setState(() => changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.bloodRed,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser != null
                                ? '${currentUser!.firstName} ${currentUser!.lastName}'
                                          .trim()
                                          .isEmpty
                                      ? currentUser!.username
                                      : '${currentUser!.firstName} ${currentUser!.lastName}'
                                : 'Driver Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(currentUser?.email ?? 'driver@example.com'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Available for deliveries'),
                    value: available,
                    activeColor: AppTheme.bloodRed,
                    onChanged: (v) => setState(() => available = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    value: notifications,
                    activeColor: AppTheme.bloodRed,
                    onChanged: (v) => setState(() => notifications = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Change Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (changeError != null)
                      Text(
                        changeError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: changingPassword ? null : changePassword,
                      child: Text(
                        changingPassword ? 'Updating...' : 'Update Password',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: widget.onLogout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
