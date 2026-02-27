import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/boreholes/presentation/borehole_detail_screen.dart';
import '../features/boreholes/presentation/borehole_form_screen.dart';
import '../features/boreholes/presentation/borehole_list_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/dashboard_shell.dart';
import '../features/finances/presentation/finance_dashboard_screen.dart';
import '../features/finances/presentation/monthly_report_screen.dart';
import '../features/finances/presentation/transaction_detail_screen.dart';
import '../features/finances/presentation/transaction_form_screen.dart';
import '../features/finances/presentation/transaction_list_screen.dart';
import '../features/investors/presentation/investor_detail_screen.dart';
import '../features/investors/presentation/investor_form_screen.dart';
import '../features/investors/presentation/investor_list_screen.dart';
import '../features/kits/presentation/kit_detail_screen.dart';
import '../features/kits/presentation/kit_form_screen.dart';
import '../features/kits/presentation/kit_list_screen.dart';
import '../features/parcels/presentation/parcel_detail_screen.dart';
import '../features/parcels/presentation/parcel_form_screen.dart';
import '../features/parcels/presentation/parcel_list_screen.dart';
import '../features/producers/presentation/producer_detail_screen.dart';
import '../features/producers/presentation/producer_form_screen.dart';
import '../features/producers/presentation/producer_list_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/trainings/presentation/training_detail_screen.dart';
import '../features/trainings/presentation/training_form_screen.dart';
import '../features/trainings/presentation/training_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      if (isLoading && currentPath == '/splash') return null;

      if (!isAuthenticated && !isLoading && currentPath != '/login') {
        return '/login';
      }

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

          // ── Producers ──
          GoRoute(
            path: '/producers',
            builder: (context, state) => const ProducerListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProducerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ProducerDetailScreen(
                    producerId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ProducerFormScreen(
                        producerId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Parcels ──
          GoRoute(
            path: '/parcels',
            builder: (context, state) => const ParcelListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ParcelFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ParcelDetailScreen(
                    parcelId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ParcelFormScreen(
                        parcelId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Boreholes ──
          GoRoute(
            path: '/boreholes',
            builder: (context, state) => const BoreholeListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const BoreholeFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => BoreholeDetailScreen(
                    boreholeId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => BoreholeFormScreen(
                        boreholeId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Kits ──
          GoRoute(
            path: '/kits',
            builder: (context, state) => const KitListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const KitFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => KitDetailScreen(
                    kitId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => KitFormScreen(
                        kitId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Trainings ──
          GoRoute(
            path: '/trainings',
            builder: (context, state) => const TrainingListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const TrainingFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => TrainingDetailScreen(
                    trainingId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => TrainingFormScreen(
                        trainingId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Finances ──
          GoRoute(
            path: '/finances',
            builder: (context, state) => const TransactionListScreen(),
            routes: [
              GoRoute(
                path: 'dashboard',
                builder: (context, state) => const FinanceDashboardScreen(),
              ),
              GoRoute(
                path: 'report',
                builder: (context, state) => const MonthlyReportScreen(),
              ),
              GoRoute(
                path: 'transactions/new',
                builder: (context, state) => const TransactionFormScreen(),
              ),
              GoRoute(
                path: 'transactions/:id',
                builder: (context, state) => TransactionDetailScreen(
                    transactionId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => TransactionFormScreen(
                        transactionId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // ── Investors ──
          GoRoute(
            path: '/investors',
            builder: (context, state) => const InvestorListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const InvestorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => InvestorDetailScreen(
                    investorId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => InvestorFormScreen(
                        investorId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
