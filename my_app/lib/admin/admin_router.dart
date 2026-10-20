import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_session.dart';
import 'screens/admin_categories_screen.dart';
import 'screens/admin_events_screen.dart';
import 'screens/admin_loading_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/not_authorized_screen.dart';
import 'widgets/admin_shell_scaffold.dart';

GoRouter buildAdminRouter(AdminSession session) {
  const adminPrefix = '/admin';

  bool isAdminRoute(String path) =>
      path == adminPrefix || path.startsWith('$adminPrefix/');

  return GoRouter(
    // Start here so we never briefly render /admin/events before redirect resolves.
    initialLocation: '$adminPrefix/loading',

    refreshListenable: session,

    redirect: (context, state) {
      final path = state.uri.path;

      // Keep everything under /admin
      if (!isAdminRoute(path)) {
        return '$adminPrefix/loading';
      }

      // If session is still checking auth/admin doc
      final stillChecking = session.loading || session.isAdmin == null;
      if (stillChecking) {
        return (path == '$adminPrefix/loading') ? null : '$adminPrefix/loading';
      }

      // signed out
      if (session.user == null) {
        return (path == '$adminPrefix/login') ? null : '$adminPrefix/login';
      }

      // signed in but not admin
      if (session.isAdmin != true) {
        return (path == '$adminPrefix/not-authorized')
            ? null
            : '$adminPrefix/not-authorized';
      }

      // authorized: keep them out of utility pages
      if (path == adminPrefix ||
          path == '$adminPrefix/' ||
          path == '$adminPrefix/login' ||
          path == '$adminPrefix/loading' ||
          path == '$adminPrefix/not-authorized') {
        return '$adminPrefix/events';
      }

      return null;
    },

    routes: [
      GoRoute(path: adminPrefix, redirect: (_, __) => '$adminPrefix/events'),
      GoRoute(
        path: '$adminPrefix/',
        redirect: (_, __) => '$adminPrefix/events',
      ),

      GoRoute(
        path: '$adminPrefix/loading',
        builder: (_, __) => const AdminLoadingScreen(),
      ),
      GoRoute(
        path: '$adminPrefix/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '$adminPrefix/not-authorized',
        builder: (_, __) =>
            NotAuthorizedScreen(email: session.user?.email ?? ''),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AdminShellScaffold(
            session: session,
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '$adminPrefix/events',
            builder: (_, __) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '$adminPrefix/categories',
            builder: (_, __) => const AdminCategoriesScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Admin route not found: ${state.uri}')),
    ),
  );
}
