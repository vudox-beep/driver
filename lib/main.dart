import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'models/models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAuthenticated = false;

  void authenticate() {
    setState(() {
      isAuthenticated = true;
    });
  }

  void logout() {
    setState(() {
      isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: isAuthenticated
          ? MainShell(onLogout: logout)
          : AuthScreen(onAuthenticated: authenticate),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/earnings': (_) => const EarningsScreen(),
        '/profile': (_) => ProfileScreen(onLogout: logout),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/orderDetails' && settings.arguments != null) {
          final order = settings.arguments as dynamic;
          return MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          );
        }
        if (settings.name == '/navigate' && settings.arguments != null) {
          final order = settings.arguments as dynamic;
          return MaterialPageRoute(
            builder: (_) => NavigationScreen(order: order),
          );
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  Order? selectedOrder;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onSelectOrder: (o) => setState(() => selectedOrder = o),
        goToDetails: () => setState(() => index = 1),
        goToNavigate: () => setState(() => index = 2),
      ),
      OrderDetailsScreen(order: selectedOrder),
      NavigationScreen(order: selectedOrder),
      const EarningsScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: AppTheme.bloodRed.withOpacity(0.2),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Details',
          ),
          NavigationDestination(
            icon: Icon(Icons.navigation),
            label: 'Navigate',
          ),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
