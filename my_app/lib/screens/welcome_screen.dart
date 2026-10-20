import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = 'welcome';
  static const routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/welcome_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),

          // Dark overlay (stronger at bottom like your design)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.40),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  Text(
                    'Discover events happening\naround you!',
                    style: tt.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Find, explore, and book tickets for concerts,\nworkshops, and gatherings across Yemen — all in\none place.',
                    style: tt.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.78),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Primary button (big)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.push(SignupScreen.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary button (white like your design)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.push(LoginScreen.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '* Discover and book events happening around you.',
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}