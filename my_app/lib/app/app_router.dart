import 'package:go_router/go_router.dart';

import '../models/event.dart';

// Auth
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/signup_screen.dart';

// Core
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';

// Main
import '../screens/main/main_screen.dart';
import '../screens/main/account_settings_screen.dart';
import '../screens/main/privacy_security_screen.dart';
import '../screens/main/help_screen.dart';

// Event flow
import '../screens/event/checkout_screen.dart';
import '../screens/event/event_details_screen.dart';
import '../screens/event/ticket_selection_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: SplashScreen.routePath,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: WelcomeScreen.routePath,
        name: WelcomeScreen.routeName,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: SignupScreen.routePath,
        name: SignupScreen.routeName,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: ForgotPasswordScreen.routePath,
        name: ForgotPasswordScreen.routeName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: OtpScreen.routePath,
        name: OtpScreen.routeName,
        builder: (context, state) {
          final email = (state.extra as String?) ?? 'example@gmail.com';
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: ResetPasswordScreen.routePath,
        name: ResetPasswordScreen.routeName,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Main app
      GoRoute(
        path: MainScreen.routePath,
        name: MainScreen.routeName,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return MainScreen(initialTab: tab);
        },
      ),

      // Profile extra screens
      GoRoute(
        path: AccountSettingsScreen.routePath,
        name: AccountSettingsScreen.routeName,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: PrivacySecurityScreen.routePath,
        name: PrivacySecurityScreen.routeName,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: HelpScreen.routePath,
        name: HelpScreen.routeName,
        builder: (context, state) => const HelpScreen(),
      ),

      // Event flow
      GoRoute(
        path: EventDetailsScreen.routePath,
        name: EventDetailsScreen.routeName,
        builder: (context, state) {
          final event = state.extra as Event;
          return EventDetailsScreen(event: event);
        },
      ),
      GoRoute(
        path: TicketSelectionScreen.routePath,
        name: TicketSelectionScreen.routeName,
        builder: (context, state) {
          final event = state.extra as Event;
          return TicketSelectionScreen(event: event);
        },
      ),
      GoRoute(
        path: CheckoutScreen.routePath,
        name: CheckoutScreen.routeName,
        builder: (context, state) {
          final payload = state.extra as CheckoutPayload;
          return CheckoutScreen(payload: payload);
        },
      ),
    ],
  );
}