import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../providers/theme/theme_provider.dart';
import '../../providers/settings/biometric_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final bioService = ref.watch(biometricAuthServiceProvider);
    final snackbar = ref.watch(snackbarServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(mode.name),
          ),
          biometricEnabled.when(
            data: (enabled) => SwitchListTile(
              title: const Text('Biometric Login'),
              subtitle: const Text('Require Face ID / Touch ID to unlock auto-login'),
              value: enabled,
              onChanged: (v) async {
                final supported = await bioService.canCheck();
                if (!supported) {
                  snackbar.showMessage('Biometrics not available on this device');
                  return;
                }
                await ref.read(biometricEnabledProvider.notifier).setEnabled(v);
              },
            ),
            loading: () => const ListTile(
              title: Text('Biometric Login'),
              subtitle: Text('Loading…'),
            ),
            error: (_, __) => const ListTile(
              title: Text('Biometric Login'),
              subtitle: Text('Failed to load'),
            ),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
            title: const Text('System'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
            title: const Text('Light'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v!),
            title: const Text('Dark'),
          ),
        ],
      ),
    );
  }
}

