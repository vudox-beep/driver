import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool available = true;
  bool notifications = true;

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
                  children: const [
                    CircleAvatar(radius: 24, backgroundColor: AppTheme.bloodRed),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('driver@example.com'),
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
