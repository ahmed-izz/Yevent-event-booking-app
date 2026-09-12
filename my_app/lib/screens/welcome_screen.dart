import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = 'welcome';
  static const routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              const Text('Discover events happening around you!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                'Find, explore, and book tickets fast — all in one place.',
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get Started',
                onPressed: () => context.push(SignupScreen.routePath),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(LoginScreen.routePath),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Login'),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}