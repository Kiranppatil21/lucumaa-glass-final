import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/providers.dart';
import 'providers/theme/theme_provider.dart';

class LucumaaErpApp extends ConsumerWidget {
  const LucumaaErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final messengerKey = ref.watch(scaffoldMessengerKeyProvider);

    return _Bootstrapper(
      child: MaterialApp.router(
        title: 'Lucumaa Glass ERP',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


class _Bootstrapper extends ConsumerStatefulWidget {
  const _Bootstrapper({required this.child});
  final Widget child;

  @override
  ConsumerState<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends ConsumerState<_Bootstrapper> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    // Fire-and-forget initialization.
    Future<void>(() async {
      try {
        await ref.read(pushNotificationsServiceProvider).init();
      } catch (e, st) {
        // Never crash the app on optional services.
        ref.read(loggerProvider).w(
          'Push notification init failed',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
