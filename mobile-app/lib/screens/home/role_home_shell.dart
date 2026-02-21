import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../models/role.dart';
import '../../providers/auth/auth_providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/coming_soon.dart';
import '../dashboard/admin/admin_dashboard_screen.dart';
import '../dashboard/dealer/dealer_dashboard_screen.dart';
import '../orders/orders_list_screen.dart';

class RoleHomeShell extends ConsumerStatefulWidget {
  const RoleHomeShell({super.key});

  @override
  ConsumerState<RoleHomeShell> createState() => _RoleHomeShellState();
}

class _RoleHomeShellState extends ConsumerState<RoleHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final role = auth.user?.role;
    final title = switch (role) {
      Role.admin => 'Admin',
      Role.manager => 'Manager',
      Role.operator => 'Operator',
      Role.sales => 'Sales',
      Role.hr => 'HR',
      Role.dealer => 'Dealer',
      _ => 'Home',
    };

    final tabs = _tabsFor(role);
    if (_index >= tabs.length) _index = 0;

    return AppScaffold(
      title: '$title Dashboard',
      drawer: _AppDrawer(
        name: auth.user?.name ?? 'User',
        role: role,
      ),
      destinations: tabs.map((t) => t.destination).toList(growable: false),
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      body: tabs[_index].builder(context),
    );
  }

  List<_RoleTab> _tabsFor(Role? role) {
    return switch (role) {
      Role.admin => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            builder: (_) => const AdminDashboardScreen(),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Orders'),
            builder: (_) => const OrdersListScreen(title: 'All Orders'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
            builder: (_) => const ComingSoon(title: 'Admin • Reports'),
          ),
        ],
      Role.dealer => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            builder: (_) => const DealerDashboardScreen(),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Orders'),
            builder: (_) => const OrdersListScreen(title: 'My Orders'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.payments), label: 'Payments'),
            builder: (_) => const ComingSoon(title: 'Dealer • Payment History'),
          ),
        ],
      Role.manager => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            builder: (_) => const ComingSoon(title: 'Manager • Dashboard'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.assignment), label: 'Assign'),
            builder: (_) => const ComingSoon(title: 'Manager • Assign Orders'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.groups), label: 'Team'),
            builder: (_) => const ComingSoon(title: 'Manager • Team Overview'),
          ),
        ],
      Role.operator => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.assignment), label: 'Orders'),
            builder: (_) => const ComingSoon(title: 'Operator • Assigned Orders'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Photos'),
            builder: (_) => const ComingSoon(title: 'Operator • Upload Work Photos'),
          ),
        ],
      Role.sales => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.add_shopping_cart), label: 'Create'),
            builder: (_) => const ComingSoon(title: 'Sales • Create Order'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
            builder: (_) => const ComingSoon(title: 'Sales • Customer Orders'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Report'),
            builder: (_) => const ComingSoon(title: 'Sales • Sales Report'),
          ),
        ],
      Role.hr => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.badge), label: 'Employees'),
            builder: (_) => const ComingSoon(title: 'HR • Employee Management'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.event_available), label: 'Attendance'),
            builder: (_) => const ComingSoon(title: 'HR • Attendance'),
          ),
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.payments), label: 'Salary'),
            builder: (_) => const ComingSoon(title: 'HR • Salary Overview'),
          ),
        ],
      _ => [
          _RoleTab(
            destination: const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            builder: (_) => const ComingSoon(title: 'Home'),
          ),
        ],
    };
  }
}

class _RoleTab {
  final NavigationDestination destination;
  final Widget Function(BuildContext) builder;

  const _RoleTab({required this.destination, required this.builder});
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.name, required this.role});

  final String name;
  final Role? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(name),
              accountEmail: Text(role?.name ?? ''),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(RoutePaths.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(RoutePaths.notifications);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(RoutePaths.settings);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authNotifierProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
