import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event.dart';

// Auth
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_screen.dart';

// Core
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';

// Main
import '../screens/main/account_settings_screen.dart';
import '../screens/main/edit_profile_screen.dart';
import '../screens/main/help_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/main/privacy_security_screen.dart';

// Event flow
import '../screens/event/all_events_screen.dart';
import '../screens/event/checkout_screen.dart';
import '../screens/event/event_details_screen.dart';
import '../screens/event/popular_events_screen.dart';
import '../screens/event/ticket_selection_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static Page<void> _fadeScalePage(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Page<void> _noTransition(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  static final _auth = FirebaseAuth.instance;

  static final router = GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: GoRouterRefreshStream(_auth.userChanges()),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // IMPORTANT: never redirect away from Splash, so it always shows ~2s.
      final isSplash = loc == SplashScreen.routePath;
      if (isSplash) return null;

      final user = _auth.currentUser;
      final loggedIn = user != null;
      final emailVerified = user?.emailVerified ?? false;

      final isOnboarding = loc == OnboardingScreen.routePath;
      final isWelcome = loc == WelcomeScreen.routePath;

      final isLogin = loc == LoginScreen.routePath;
      final isSignup = loc == SignupScreen.routePath;
      final isForgot = loc == ForgotPasswordScreen.routePath;
      final isVerify = loc == VerifyEmailScreen.routePath;

      final isPublicWhenLoggedOut =
          isOnboarding || isWelcome || isLogin || isSignup || isForgot;

      // Logged out: allow only public screens (and Splash is already allowed above)
      if (!loggedIn) {
        return isPublicWhenLoggedOut ? null : SplashScreen.routePath;
      }

      // Logged in but not verified: force Verify Email (allow staying on it)
      if (!emailVerified) {
        return isVerify ? null : VerifyEmailScreen.routePath;
      }

      // Logged in + verified: keep users out of auth/onboarding screens
      final isAuthLike =
          isOnboarding || isWelcome || isLogin || isSignup || isForgot || isVerify;
      if (isAuthLike) return MainScreen.routePath;

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        pageBuilder: (context, state) =>
            _noTransition(state, const SplashScreen()),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: WelcomeScreen.routePath,
        name: WelcomeScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const WelcomeScreen()),
      ),

      // Auth
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: SignupScreen.routePath,
        name: SignupScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: ForgotPasswordScreen.routePath,
        name: ForgotPasswordScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: VerifyEmailScreen.routePath,
        name: VerifyEmailScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const VerifyEmailScreen()),
      ),

      // Main
      GoRoute(
        path: MainScreen.routePath,
        name: MainScreen.routeName,
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];

          // Fixed key prevents re-creating/animating MainScreen when only ?tab changes.
          return NoTransitionPage<void>(
            key: const ValueKey('MainScreen'),
            child: MainScreen(initialTab: tab),
          );
        },
      ),

      // Profile extra screens
      GoRoute(
        path: AccountSettingsScreen.routePath,
        name: AccountSettingsScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const AccountSettingsScreen()),
      ),
      GoRoute(
        path: PrivacySecurityScreen.routePath,
        name: PrivacySecurityScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const PrivacySecurityScreen()),
      ),
      GoRoute(
        path: EditProfileScreen.routePath,
        name: EditProfileScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: HelpScreen.routePath,
        name: HelpScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const HelpScreen()),
      ),

      // Events list screens
      GoRoute(
        path: AllEventsScreen.routePath,
        name: AllEventsScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const AllEventsScreen()),
      ),
      GoRoute(
        path: PopularEventsScreen.routePath,
        name: PopularEventsScreen.routeName,
        pageBuilder: (context, state) =>
            _fadeScalePage(state, const PopularEventsScreen()),
      ),

      // NEW: Event details deep link (/event/:id)
      // NEW: shareable, refresh-safe
GoRoute(
  path: EventDetailsScreen.routePattern, // '/event/:id'
  name: EventDetailsScreen.routeName,
  pageBuilder: (context, state) {
    final id = state.pathParameters['id']!;
    final initial = state.extra is Event ? state.extra as Event : null;
    return _fadeScalePage(
      state,
      EventDetailsScreen(eventId: id, initialEvent: initial),
    );
  },
),

// LEGACY: keeps old navigation working (uses extra)
GoRoute(
  path: EventDetailsScreen.legacyRoutePath, // '/event-details'
  pageBuilder: (context, state) {
    final extra = state.extra;
    if (extra is! Event) {
      return _fadeScalePage(
        state,
        const Scaffold(
          body: SafeArea(
            child: Center(child: Text('Missing event data.')),
          ),
        ),
      );
    }
    return _fadeScalePage(state, EventDetailsScreen.fromEvent(extra));
  },
),

      GoRoute(
  path: TicketSelectionScreen.routePath,
  name: TicketSelectionScreen.routeName,
  pageBuilder: (context, state) {
    final extra = state.extra;

    if (extra is! Event) {
      return _fadeScalePage(
        state,
        _InvalidFlowScreen(
          title: 'Select Tickets',
          message: 'Please open ticket booking from an event page.',
          primaryActionText: 'Back to Home',
          onPrimaryAction: () => context.go(MainScreen.routePath),
        ),
      );
    }

    return _fadeScalePage(state, TicketSelectionScreen(event: extra));
  },
),

GoRoute(
  path: CheckoutScreen.routePath,
  name: CheckoutScreen.routeName,
  pageBuilder: (context, state) {
    final extra = state.extra;

    if (extra is! CheckoutPayload) {
      return _fadeScalePage(
        state,
        _InvalidFlowScreen(
          title: 'Checkout',
          message: 'Checkout session expired. Please start again from an event.',
          primaryActionText: 'Back to Home',
          onPrimaryAction: () => context.go(MainScreen.routePath),
        ),
      );
    }

    return _fadeScalePage(state, CheckoutScreen(payload: extra));
  },
),

    ],
  );
}

class _InvalidFlowScreen extends StatelessWidget {
  const _InvalidFlowScreen({
    required this.title,
    required this.message,
    required this.primaryActionText,
    required this.onPrimaryAction,
  });

  final String title;
  final String message;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onPrimaryAction,
                child: Text(primaryActionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}