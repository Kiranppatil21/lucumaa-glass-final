import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';

class DealerDashboardScreen extends StatelessWidget {
  const DealerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dealer Summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _DealerCard(title: 'Place New Order', icon: Icons.add_shopping_cart, onTap: () => context.push(RoutePaths.dealerNewOrder)),
        const SizedBox(height: 12),
        _DealerCard(title: 'Track Orders', icon: Icons.local_shipping, onTap: () => context.push(RoutePaths.dealerTrackOrders)),
        const SizedBox(height: 12),
        _DealerCard(title: 'Payment History', icon: Icons.payments, onTap: () => context.push(RoutePaths.dealerPayments)),
      ],
    );
  }
}

class _DealerCard extends StatelessWidget {
  const _DealerCard({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

