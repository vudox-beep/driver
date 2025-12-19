import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final licenseNumberController = TextEditingController();
  bool agreedMarketing = false;
  bool isLogin = true;
  bool isSubmitting = false;
  String? noticeMessage;
  bool noticeIsError = true;
  String get apiBaseUrl => DriverSession.apiBaseUrl;

  Future<void> submit() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    try {
      if (isLogin) {
        final u = await ApiClient.login(
          emailController.text.trim(),
          passwordController.text,
        );
        if (u != null) {
          if ((u.driverStatus ?? '').toLowerCase() == 'inactive') {
            final msg = 'Driver registered successfully. Awaiting admin approval. Check your email.';
            setState(() {
              noticeMessage = msg;
              noticeIsError = false;
            });
            setState(() => isLogin = true);
          } else {
            currentUser = u;
            widget.onAuthenticated();
          }
        } else {
          const msg = 'Incorrect email or password';
          setState(() {
            noticeMessage = msg;
            noticeIsError = true;
          });
        }
      } else {
        final resp = await ApiClient.signup({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'date_of_birth': dobController.text.trim(),
          'vehicle_type': vehicleTypeController.text.trim(),
          'vehicle_plate': vehiclePlateController.text.trim(),
          'license_number': licenseNumberController.text.trim(),
          'agreed_marketing': agreedMarketing ? 1 : 0,
        });
        if (resp != null) {
          final success = resp['success'] == true;
          final message = (resp['message'] ?? resp['error'] ?? '')?.toString() ?? '';
          if (!success) {
            if (message.isNotEmpty) {
              setState(() {
                noticeMessage = message;
                noticeIsError = true;
              });
            }
          } else {
            final bigMsg = message.isNotEmpty
                ? message
                : 'Congratulations! You have signed up as a driver. Please wait for approval and check your email.';
            setState(() {
              noticeMessage = bigMsg;
              noticeIsError = false;
            });
            setState(() => isLogin = true);
          }
        }
      }
    } catch (e) {
      final msg = e.toString();
      setState(() {
        noticeMessage = msg;
        noticeIsError = true;
      });
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  isLogin ? 'Driver Login' : 'Create Driver Account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isLogin)
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                const SizedBox(height: 12),
                if (noticeMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: noticeIsError
                          ? Colors.red.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                      border: Border.all(
                        color:
                            noticeIsError ? Colors.redAccent : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          noticeIsError
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color:
                              noticeIsError ? Colors.redAccent : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            noticeMessage!,
                            style: TextStyle(
                              color: noticeIsError
                                  ? Colors.redAccent
                                  : Colors.green.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => noticeMessage = null),
                          icon: const Icon(Icons.close),
                          color:
                              noticeIsError ? Colors.redAccent : Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: isLogin ? 'Email or Username' : 'Email',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vehicleTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vehiclePlateController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Plate',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: licenseNumberController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: agreedMarketing,
                        activeColor: AppTheme.bloodRed,
                        onChanged: (v) =>
                            setState(() => agreedMarketing = v ?? false),
                      ),
                      const Text('Agree to marketing'),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isLogin ? 'Sign In' : 'Register'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? 'No account? Register'
                        : 'Have an account? Sign In',
                    style: const TextStyle(color: AppTheme.bloodRed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
