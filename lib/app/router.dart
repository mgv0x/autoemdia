import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/setup_missing_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/expenses/domain/expense_entity.dart';
import '../features/expenses/presentation/pages/expense_detail_page.dart';
import '../features/expenses/presentation/pages/expense_form_page.dart';
import '../features/expenses/presentation/pages/expenses_page.dart';
import '../features/maintenance/domain/maintenance_entity.dart';
import '../features/maintenance/presentation/pages/maintenance_detail_page.dart';
import '../features/maintenance/presentation/pages/maintenance_form_page.dart';
import '../features/maintenance/presentation/pages/maintenance_page.dart';
import '../features/reminders/domain/reminder_entity.dart';
import '../features/reminders/presentation/pages/reminder_detail_page.dart';
import '../features/reminders/presentation/pages/reminder_form_page.dart';
import '../features/reminders/presentation/pages/reminders_page.dart';
import '../features/settings/presentation/pages/more_page.dart';
import '../features/settings/presentation/pages/my_car_page.dart';
import '../features/subscription/presentation/pages/premium_page.dart';
import '../features/vehicle/domain/vehicle_entity.dart';
import '../features/vehicle/presentation/pages/vehicle_form_page.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router principal com redirect por autenticação.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStreamProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isSetupMissing = location == '/setup-missing';
      final isAuthRoute =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password';

      final loggedIn = authState.value?.id != null;

      if (isSplash || isSetupMissing) return null;

      if (!loggedIn) {
        // Não autenticado: só pode ir para rotas públicas ou splash.
        return isAuthRoute ? null : '/login';
      }

      // Autenticado tentando ir para tela pública: volta para home.
      if (isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/setup-missing',
        builder: (context, state) => const SetupMissingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Fluxo inicial / fora do shell
      GoRoute(
        path: '/vehicle/new',
        builder: (context, state) {
          final first = state.uri.queryParameters['first'] == 'true';
          return VehicleFormPage(isFirstVehicle: first);
        },
      ),
      GoRoute(
        path: '/vehicle/edit',
        builder: (context, state) =>
            VehicleFormPage(vehicle: state.extra as VehicleEntity?),
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) => const MaintenanceFormPage(),
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) => MaintenanceDetailPage(
          maintenance: state.extra as MaintenanceEntity,
        ),
      ),
      GoRoute(
        path: '/maintenance/:id/edit',
        builder: (context, state) =>
            MaintenanceFormPage(maintenance: state.extra as MaintenanceEntity?),
      ),
      GoRoute(
        path: '/reminders/new',
        builder: (context, state) => const ReminderFormPage(),
      ),
      GoRoute(
        path: '/reminders/:id',
        builder: (context, state) =>
            ReminderDetailPage(reminder: state.extra as ReminderEntity),
      ),
      GoRoute(
        path: '/reminders/:id/edit',
        builder: (context, state) =>
            ReminderFormPage(reminder: state.extra as ReminderEntity?),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => const ExpenseFormPage(),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (context, state) =>
            ExpenseDetailPage(expense: state.extra as ExpenseEntity),
      ),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (context, state) =>
            ExpenseFormPage(expense: state.extra as ExpenseEntity?),
      ),
      GoRoute(path: '/my-car', builder: (context, state) => const MyCarPage()),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumPage(),
      ),

      // Shell com bottom navigation (5 abas)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/maintenance',
                builder: (context, state) => const MaintenanceListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const RemindersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Página não encontrada'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir para início'),
            ),
          ],
        ),
      ),
    ),
  );
});
