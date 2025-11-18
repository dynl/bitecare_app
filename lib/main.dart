import 'package:flutter/material.dart';
import 'package:bitecare_app/screens/login_screen.dart';
import 'package:bitecare_app/screens/dashboard_screen.dart';
import 'package:bitecare_app/services/api_service.dart';

void main() {
  // 1. We REMOVED "await ApiService.loadToken()"
  // This ensures the app forgets the user every time it restarts.

  runApp(const BiteCareApp());
}

class BiteCareApp extends StatelessWidget {
  const BiteCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Since we didn't load the token, this will always be null/false on refresh
    final bool isLoggedIn = ApiService.authToken != null;

    return MaterialApp(
      title: 'Animal BiteCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      // This will now always default to LoginScreen on refresh
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
