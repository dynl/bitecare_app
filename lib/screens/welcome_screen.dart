import 'package:flutter/material.dart';
import 'package:bitecare_app/screens/login_screen.dart';
import 'package:bitecare_app/bitecare_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 30),

              const Text(
                "Welcome to BiteCare",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BiteCareTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              const Text(
                "Schedule your anti-rabies shot in just a few taps.",
                style: TextStyle(fontSize: 16, color: BiteCareTheme.textGrey),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("GET STARTED"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
