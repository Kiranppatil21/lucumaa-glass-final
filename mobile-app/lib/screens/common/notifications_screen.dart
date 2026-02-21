import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 600)),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('Notification ${i + 1}'),
            subtitle: const Text('This is a placeholder notification.'),
          ),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: 12,
        ),
      ),
    );
  }
}
