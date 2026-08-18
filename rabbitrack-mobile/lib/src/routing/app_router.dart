import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/activity/activity_list_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/breeding/mating_create_screen.dart';
import '../features/breeding/mating_detail_screen.dart';
import '../features/breeding/mating_list_screen.dart';
import '../features/breeding/pregnancy_check_screen.dart';
import '../features/diagnostics/api_status_screen.dart';
import '../features/expenses/expense_create_screen.dart';
import '../features/expenses/expense_list_screen.dart';
import '../features/farms/farm_create_screen.dart';
import '../features/farms/farm_selection_screen.dart';
import '../features/farms/farm_settings_screen.dart';
import '../features/health/health_create_screen.dart';
import '../features/health/health_list_screen.dart';
import '../features/health/treatment_create_screen.dart';
import '../features/home/home_screen.dart';
import '../features/litters/kindling_create_screen.dart';
import '../features/litters/litter_check_screen.dart';
import '../features/litters/litter_conversion_screen.dart';
import '../features/litters/litter_detail_screen.dart';
import '../features/litters/litter_foster_screen.dart';
import '../features/litters/litter_list_screen.dart';
import '../features/litters/weaning_create_screen.dart';
import '../features/locations/location_create_screen.dart';
import '../features/locations/location_detail_screen.dart';
import '../features/locations/location_edit_screen.dart';
import '../features/locations/location_list_screen.dart';
import '../features/more/more_screen.dart';
import '../features/rabbits/rabbit_create_screen.dart';
import '../features/rabbits/rabbit_detail_screen.dart';
import '../features/rabbits/rabbit_edit_screen.dart';
import '../features/rabbits/rabbit_list_screen.dart';
import '../features/rabbits/rabbit_move_screen.dart';
import '../features/rabbits/rabbit_status_screen.dart';
import '../features/reports/breeding_calendar_screen.dart';
import '../features/reports/buck_performance_report_screen.dart';
import '../features/reports/doe_performance_report_screen.dart';
import '../features/reports/finance_report_screen.dart';
import '../features/reports/health_report_screen.dart';
import '../features/reports/litter_performance_report_screen.dart';
import '../features/reports/population_report_screen.dart';
import '../features/sales/sale_create_screen.dart';
import '../features/sales/sale_list_screen.dart';
import '../features/team/team_add_screen.dart';
import '../features/team/team_list_screen.dart';
import '../features/tasks/task_create_screen.dart';
import '../features/tasks/task_list_screen.dart';
import '../features/weights/weight_create_screen.dart';
import '../features/weights/weight_list_screen.dart';
import '../navigation/main_navigation_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = authState.valueOrNull;
      final path = state.uri.path;
      final isAuthRoute = {
        '/login',
        '/signup',
        '/forgot-password',
        '/reset-password',
      }.contains(path);
      final isPublicRoute = isAuthRoute || path == '/api-status';

      if (session == null && !isPublicRoute) {
        return '/login';
      }

      if (session != null && isAuthRoute) {
        return session.selectedFarm == null ? '/farms' : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/api-status',
        builder: (context, state) => const ApiStatusScreen(),
      ),
      GoRoute(
        path: '/farms',
        builder: (context, state) => const FarmSelectionScreen(),
      ),
      GoRoute(
        path: '/farms/new',
        builder: (context, state) => const FarmCreateScreen(),
      ),
      GoRoute(
        path: '/farms/settings',
        builder: (context, state) => const FarmSettingsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScaffold(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              final session = ref.watch(authControllerProvider).valueOrNull;

              return HomeScreen(farm: session?.selectedFarm);
            },
          ),
          GoRoute(
            path: '/rabbits',
            builder: (context, state) => const RabbitListScreen(),
          ),
          GoRoute(
            path: '/rabbits/new',
            builder: (context, state) => const RabbitCreateScreen(),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId',
            builder: (context, state) =>
                RabbitDetailScreen(rabbitId: state.pathParameters['rabbitId']!),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId/edit',
            builder: (context, state) =>
                RabbitEditScreen(rabbitId: state.pathParameters['rabbitId']!),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId/move',
            builder: (context, state) =>
                RabbitMoveScreen(rabbitId: state.pathParameters['rabbitId']!),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId/status',
            builder: (context, state) =>
                RabbitStatusScreen(rabbitId: state.pathParameters['rabbitId']!),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId/sale',
            builder: (context, state) => SaleCreateScreen(
              initialRabbitId: state.pathParameters['rabbitId']!,
            ),
          ),
          GoRoute(
            path: '/rabbits/:rabbitId/weight',
            builder: (context, state) => WeightCreateScreen(
              initialRabbitId: state.pathParameters['rabbitId']!,
            ),
          ),
          GoRoute(
            path: '/breeding',
            builder: (context, state) => MatingListScreen(
              rabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/breeding/new',
            builder: (context, state) => MatingCreateScreen(
              initialRabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/breeding/:matingId',
            builder: (context, state) =>
                MatingDetailScreen(matingId: state.pathParameters['matingId']!),
          ),
          GoRoute(
            path: '/breeding/:matingId/pregnancy-check',
            builder: (context, state) => PregnancyCheckScreen(
              matingId: state.pathParameters['matingId']!,
              isRevision: state.uri.queryParameters['revise'] == '1',
            ),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => HealthListScreen(
              rabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/health/new',
            builder: (context, state) => HealthCreateScreen(
              initialRabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/health/:healthEventId/treatments/new',
            builder: (context, state) => TreatmentCreateScreen(
              healthEventId: state.pathParameters['healthEventId']!,
            ),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TaskListScreen(),
          ),
          GoRoute(
            path: '/tasks/new',
            builder: (context, state) => const TaskCreateScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) =>
                SaleListScreen(rabbitId: state.uri.queryParameters['rabbitId']),
          ),
          GoRoute(
            path: '/sales/new',
            builder: (context, state) => SaleCreateScreen(
              initialRabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/expenses/new',
            builder: (context, state) => const ExpenseCreateScreen(),
          ),
          GoRoute(
            path: '/reports/finance',
            builder: (context, state) => const FinanceReportScreen(),
          ),
          GoRoute(
            path: '/reports/breeding-calendar',
            builder: (context, state) => const BreedingCalendarScreen(),
          ),
          GoRoute(
            path: '/reports/population',
            builder: (context, state) => const PopulationReportScreen(),
          ),
          GoRoute(
            path: '/reports/health',
            builder: (context, state) => const HealthReportScreen(),
          ),
          GoRoute(
            path: '/reports/litters/performance',
            builder: (context, state) => const LitterPerformanceReportScreen(),
          ),
          GoRoute(
            path: '/reports/does/performance',
            builder: (context, state) => const DoePerformanceReportScreen(),
          ),
          GoRoute(
            path: '/reports/bucks/performance',
            builder: (context, state) => const BuckPerformanceReportScreen(),
          ),
          GoRoute(
            path: '/team',
            builder: (context, state) => const TeamListScreen(),
          ),
          GoRoute(
            path: '/team/new',
            builder: (context, state) => const TeamAddScreen(),
          ),
          GoRoute(
            path: '/activity',
            builder: (context, state) => const ActivityListScreen(),
          ),
          GoRoute(
            path: '/locations',
            builder: (context, state) => const LocationListScreen(),
          ),
          GoRoute(
            path: '/locations/new',
            builder: (context, state) => const LocationCreateScreen(),
          ),
          GoRoute(
            path: '/locations/:locationId/edit',
            builder: (context, state) => LocationEditScreen(
              locationId: state.pathParameters['locationId']!,
            ),
          ),
          GoRoute(
            path: '/locations/:locationId',
            builder: (context, state) => LocationDetailScreen(
              locationId: state.pathParameters['locationId']!,
            ),
          ),
          GoRoute(
            path: '/litters',
            builder: (context, state) => const LitterListScreen(),
          ),
          GoRoute(
            path: '/litters/new',
            builder: (context, state) => KindlingCreateScreen(
              initialMatingId: state.uri.queryParameters['matingId'],
            ),
          ),
          GoRoute(
            path: '/litters/:litterId',
            builder: (context, state) =>
                LitterDetailScreen(litterId: state.pathParameters['litterId']!),
          ),
          GoRoute(
            path: '/litters/:litterId/weaning',
            builder: (context, state) => WeaningCreateScreen(
              litterId: state.pathParameters['litterId']!,
            ),
          ),
          GoRoute(
            path: '/litters/:litterId/checks/new',
            builder: (context, state) =>
                LitterCheckScreen(litterId: state.pathParameters['litterId']!),
          ),
          GoRoute(
            path: '/litters/:litterId/fosters/new',
            builder: (context, state) =>
                LitterFosterScreen(litterId: state.pathParameters['litterId']!),
          ),
          GoRoute(
            path: '/litters/:litterId/convert',
            builder: (context, state) => LitterConversionScreen(
              litterId: state.pathParameters['litterId']!,
            ),
          ),
          GoRoute(
            path: '/litters/:litterId/weight',
            builder: (context, state) => WeightCreateScreen(
              initialLitterId: state.pathParameters['litterId']!,
            ),
          ),
          GoRoute(
            path: '/weights',
            builder: (context, state) => WeightListScreen(
              rabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
          GoRoute(
            path: '/weights/new',
            builder: (context, state) => WeightCreateScreen(
              initialRabbitId: state.uri.queryParameters['rabbitId'],
            ),
          ),
        ],
      ),
    ],
  );
});
