import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_wordmark.dart';
import 'auth/verify_email_screen.dart';
import 'main/main_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = 'splash';

  // Keep matching AppRouter.
  static const routePath = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _reveal;
  late final Animation<double> _glow;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.00, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.03)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.00, 0.70)),
    );

    _reveal = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
    );

    _glow = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
    );

    _c.forward();

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      context.go(OnboardingScreen.routePath);
      return;
    }

    // If you're using the router redirect guard, this is still fine,
    // but this prevents an extra redirect hop.
    if (!user.emailVerified) {
      context.go(VerifyEmailScreen.routePath);
      return;
    }

    context.go(MainScreen.routePath);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Make the “guiding photos/logo” a little smaller here:
    const double wordmarkHeight = 52; // was 56

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final glowStrength = _glow.value;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Slightly smaller glow as well (optional)
                  Container(
                    width: 205, // was 220
                    height: 112, // was 120
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.18 * glowStrength),
                          blurRadius: 50 * glowStrength,
                          spreadRadius: 6 * glowStrength,
                        ),
                      ],
                    ),
                  ),

                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _reveal.value.clamp(0.0, 1.0),
                            child: const AppWordmark(height: wordmarkHeight),
                          ),
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
    );
  }
}