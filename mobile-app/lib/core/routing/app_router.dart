import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/role.dart';
import '../../providers/auth/auth_providers.dart';
import '../../providers/auth/auth_state.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/common/notifications_screen.dart';
import '../../screens/common/profile_screen.dart';
import '../../screens/common/settings_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/admin/dealer_management_screen.dart';
import '../../screens/admin/employee_management_screen.dart';
import '../../screens/manager/assign_orders_screen.dart';
import '../../screens/manager/manager_reports_screen.dart';
import '../../screens/manager/team_overview_screen.dart';
import '../../screens/operator/assigned_orders_screen.dart';
import '../../screens/operator/update_order_status_screen.dart';
import '../../screens/operator/upload_work_photos_screen.dart';
import '../../screens/sales/create_order_screen.dart';
import '../../screens/sales/customer_orders_screen.dart';
import '../../screens/sales/sales_report_screen.dart';
import '../../screens/hr/hr_employee_management_screen.dart';
import '../../screens/hr/attendance_screen.dart';
import '../../screens/hr/salary_overview_screen.dart';
import '../../screens/dealer/place_new_order_screen.dart';
import '../../screens/dealer/track_orders_screen.dart';
import '../../screens/dealer/payment_history_screen.dart';
import '../../screens/orders/orders_list_screen.dart';
import '../../screens/home/role_home_shell.dart';
import '../../screens/splash/splash_screen.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authNotifierProvider);
  final routerNotifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == RoutePaths.login;
      final isForgot = state.matchedLocation == RoutePaths.forgotPassword;
      final isSplash = state.matchedLocation == RoutePaths.splash;

      if (auth.status == AuthStatus.unknown) {
        return isSplash ? null : RoutePaths.splash;
      }

      final loggedIn = auth.status == AuthStatus.authenticated;
      if (!loggedIn) {
        if (isLoggingIn || isForgot) return null;
        return RoutePaths.login;
      }

      // Logged in
      if (isLoggingIn || isSplash) {
        return RoutePaths.home;
      }

      // Role validation per-route
      final role = auth.user?.role;
      if (role == null) return RoutePaths.login;
      final allowed = _allowedRolesForLocation(state.matchedLocation);
      if (allowed != null && !allowed.contains(role)) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (_, __) => const RoleHomeShell(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      // Admin
      GoRoute(path: RoutePaths.adminUsers, builder: (_, __) => const ManageUsersScreen()),
      GoRoute(path: RoutePaths.adminOrders, builder: (_, __) => const OrdersListScreen(title: 'All Orders')),
      GoRoute(path: RoutePaths.adminReports, builder: (_, __) => const AdminReportsScreen()),
      GoRoute(path: RoutePaths.adminDealers, builder: (_, __) => const DealerManagementScreen()),
      GoRoute(path: RoutePaths.adminEmployees, builder: (_, __) => const EmployeeManagementScreen()),

      // Manager
      GoRoute(path: RoutePaths.managerAssignOrders, builder: (_, __) => const AssignOrdersScreen()),
      GoRoute(path: RoutePaths.managerReports, builder: (_, __) => const ManagerReportsScreen()),
      GoRoute(path: RoutePaths.managerTeam, builder: (_, __) => const TeamOverviewScreen()),

      // Operator
      GoRoute(path: RoutePaths.operatorAssignedOrders, builder: (_, __) => const AssignedOrdersScreen()),
      GoRoute(path: RoutePaths.operatorUpdateStatus, builder: (_, __) => const UpdateOrderStatusScreen()),
      GoRoute(path: RoutePaths.operatorUploadPhotos, builder: (_, __) => const UploadWorkPhotosScreen()),

      // Sales
      GoRoute(path: RoutePaths.salesCreateOrder, builder: (_, __) => const CreateOrderScreen()),
      GoRoute(path: RoutePaths.salesCustomerOrders, builder: (_, __) => const CustomerOrdersScreen()),
      GoRoute(path: RoutePaths.salesReport, builder: (_, __) => const SalesReportScreen()),

      // HR
      GoRoute(path: RoutePaths.hrEmployees, builder: (_, __) => const HrEmployeeManagementScreen()),
      GoRoute(path: RoutePaths.hrAttendance, builder: (_, __) => const AttendanceScreen()),
      GoRoute(path: RoutePaths.hrSalary, builder: (_, __) => const SalaryOverviewScreen()),

      // Dealer
      GoRoute(path: RoutePaths.dealerNewOrder, builder: (_, __) => const PlaceNewOrderScreen()),
      GoRoute(path: RoutePaths.dealerTrackOrders, builder: (_, __) => const TrackOrdersScreen()),
      GoRoute(path: RoutePaths.dealerPayments, builder: (_, __) => const PaymentHistoryScreen()),
    ],
  );
});

Set<Role>? _allowedRolesForLocation(String location) {
  // Extend this map as role-specific screens are added.
  return switch (location) {
    // Admin
    RoutePaths.adminUsers || RoutePaths.adminOrders || RoutePaths.adminReports || RoutePaths.adminDealers || RoutePaths.adminEmployees => {Role.admin},

    // Manager
    RoutePaths.managerAssignOrders || RoutePaths.managerReports || RoutePaths.managerTeam => {Role.manager},

    // Operator
    RoutePaths.operatorAssignedOrders || RoutePaths.operatorUpdateStatus || RoutePaths.operatorUploadPhotos => {Role.operator},

    // Sales
    RoutePaths.salesCreateOrder || RoutePaths.salesCustomerOrders || RoutePaths.salesReport => {Role.sales},

    // HR
    RoutePaths.hrEmployees || RoutePaths.hrAttendance || RoutePaths.hrSalary => {Role.hr},

    // Dealer
    RoutePaths.dealerNewOrder || RoutePaths.dealerTrackOrders || RoutePaths.dealerPayments => {Role.dealer},

    _ => null,
  };
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  final notifier = _RouterNotifier();
  ref.listen<AuthState>(authNotifierProvider, (_, __) {
    notifier.notify();
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
