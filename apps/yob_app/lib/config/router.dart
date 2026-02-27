import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/dashboard_shell.dart';
import '../features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      // Still loading — stay on splash
      if (isLoading && currentPath == '/splash') return null;

      // Not authenticated — redirect to login
      if (!isAuthenticated && !isLoading && currentPath != '/login') {
        return '/login';
      }

      // Authenticated — redirect away from login/splash
      if (isAuthenticated &&
          (currentPath == '/login' || currentPath == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/producers',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Producteurs',
              icon: Icons.people_rounded,
            ),
          ),
          GoRoute(
            path: '/parcels',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Parcelles',
              icon: Icons.map_rounded,
            ),
          ),
          GoRoute(
            path: '/boreholes',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Forages',
              icon: Icons.water_drop_rounded,
            ),
          ),
          GoRoute(
            path: '/kits',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Kits Agricoles',
              icon: Icons.inventory_2_rounded,
            ),
          ),
          GoRoute(
            path: '/trainings',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Formations',
              icon: Icons.school_rounded,
            ),
          ),
          GoRoute(
            path: '/finances',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Finances',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
          GoRoute(
            path: '/investors',
            builder: (context, state) => const _PlaceholderScreen(
              title: 'Investisseurs',
              icon: Icons.handshake_rounded,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Placeholder screen for modules not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Module en cours de développement',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
