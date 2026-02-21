import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/sensitive_screen.dart';
import '../../providers/auth/auth_providers.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;

    return SensitiveScreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '-', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.email ?? ''),
              const SizedBox(height: 4),
              Text('Role: ${user?.role.name ?? '-'}'),
              const Spacer(),
              PrimaryButton(
                label: 'Logout',
                onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
