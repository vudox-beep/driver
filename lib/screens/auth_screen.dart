import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

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
  final locationController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  bool agreedMarketing = false;
  bool isLogin = false;
  bool isSubmitting = false;
  String? noticeMessage;
  bool noticeIsError = true;
  String get apiBaseUrl => DriverSession.apiBaseUrl;
  XFile? profilePhoto;
  double? latitude;
  double? longitude;
  bool locating = false;

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 1,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (x != null) {
        setState(() => profilePhoto = x);
      }
    } catch (e) {
      setState(() {
        noticeMessage = e.toString();
        noticeIsError = true;
      });
    }
  }

  Future<void> getLocation() async {
    if (locating) return;
    setState(() => locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
        locationController.text =
            pos.latitude.toString() + ',' + pos.longitude.toString();
        latController.text = pos.latitude.toString();
        lngController.text = pos.longitude.toString();
      });
    } catch (e) {
      setState(() {
        noticeMessage = e.toString();
        noticeIsError = true;
      });
    } finally {
      setState(() => locating = false);
    }
  }

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
            final msg =
                'Driver registered successfully. Awaiting admin approval. Check your email.';
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
        if (latitude == null || longitude == null) {
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best,
            );
            latitude = pos.latitude;
            longitude = pos.longitude;
          } catch (_) {}
        }
        final payload = {
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
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        };
        final resp = await ApiClient.signupMultipart(
          payload,
          profilePhoto?.path,
        );
        if (resp != null) {
          final success = resp['success'] == true;
          final message =
              (resp['message'] ?? resp['error'] ?? '')?.toString() ?? '';
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
    if (!isLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getLocation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.bloodRed, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isLogin
                              ? 'Welcome back'
                              : 'Create your driver account',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Login'),
                          selected: isLogin,
                          onSelected: (_) => setState(() => isLogin = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Sign Up'),
                          selected: !isLogin,
                          onSelected: (_) {
                            setState(() => isLogin = false);
                            getLocation();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (noticeMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: noticeIsError
                              ? Colors.red.withOpacity(0.08)
                              : Colors.green.withOpacity(0.08),
                          border: Border.all(
                            color: noticeIsError
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              noticeIsError
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: noticeIsError
                                  ? Colors.redAccent
                                  : Colors.green,
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
                              onPressed: () =>
                                  setState(() => noticeMessage = null),
                              icon: const Icon(Icons.close),
                              color: noticeIsError
                                  ? Colors.redAccent
                                  : Colors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: isLogin
                                    ? 'Email or Username'
                                    : 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            if (isLogin) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onPressed: locating ? null : getLocation,
                            child: Text(
                              locating ? 'Locating...' : 'Use Current Location',
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (latitude != null && longitude != null)
                            Row(
                              children: const [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 6),
                                Text(
                                  'Location detected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 600;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: firstNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'First Name',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: lastNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Last Name',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: dobController,
                                      decoration: const InputDecoration(
                                        labelText: 'Date of Birth (YYYY-MM-DD)',
                                        prefixIcon: Icon(Icons.calendar_today),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 600;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: vehicleTypeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Vehicle Type',
                                        prefixIcon: Icon(Icons.directions_car),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: vehiclePlateController,
                                      decoration: const InputDecoration(
                                        labelText: 'Vehicle Plate',
                                        prefixIcon: Icon(
                                          Icons.confirmation_number_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: TextField(
                                      controller: licenseNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'License Number',
                                        prefixIcon: Icon(
                                          Icons.assignment_ind_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Profile Photo'),
                                    const SizedBox(height: 4),
                                    Text(
                                      profilePhoto?.name ?? 'No file selected',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: pickPhoto,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Browse'),
                              ),
                              const SizedBox(width: 8),
                              if (profilePhoto != null)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => profilePhoto = null),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Clear'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : submit,
                      child: Text(isLogin ? 'Sign In' : 'Sign Up'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? 'No account? Sign Up'
                            : 'Have an account? Sign In',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
