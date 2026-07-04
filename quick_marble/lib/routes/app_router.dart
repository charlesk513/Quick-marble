import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

/// Route paths centralized here to avoid magic strings scattered across
/// the app.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  // Clients, quotations, contracts, reports, settings routes are added
  // as each of those modules is built.
}

/// Bridges a Riverpod stream to something GoRouter's `refreshListenable`
/// can listen to, so navigation re-evaluates whenever auth state changes
/// (e.g. automatic redirect to login on sign-out).
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<void> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(authService.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = authService.currentUser != null;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (isSplash) return null; // let splash decide once it finishes checking

      if (!isLoggedIn && !isGoingToLogin) return AppRoutes.login;
      if (isLoggedIn && isGoingToLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
