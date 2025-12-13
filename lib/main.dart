import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitecare_app/providers/auth_provider.dart';
import 'package:bitecare_app/screens/dashboard_screen.dart';
import 'package:bitecare_app/screens/welcome_screen.dart';
import 'package:bitecare_app/bitecare_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const BiteCareApp(),
    ),
  );
}

class BiteCareApp extends StatelessWidget {
  const BiteCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal BiteCare',
      debugShowCheckedModeBanner: false,
      // APPLY THEME HERE
      theme: BiteCareTheme.theme, 
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return authProvider.isLoggedIn
              ? const DashboardScreen()
              : const WelcomeScreen(); 
        },
      ),
    );
  }
}