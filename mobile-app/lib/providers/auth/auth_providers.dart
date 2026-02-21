import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/di/providers.dart';
import '../../core/network/dio_factory.dart';
import '../../core/network/offline_interceptor.dart';
import '../../services/auth/auth_api.dart';
import '../../services/auth/auth_repository.dart';
import '../settings/biometric_settings_provider.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

final cacheOptionsProvider = FutureProvider<CacheOptions>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final store = HiveCacheStore('${dir.path}/dio_cache');
  return CacheOptions(
    store: store,
    policy: CachePolicy.request,
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
  );
});

final unauthenticatedDioProvider = Provider<Dio>((ref) {
  final logger = ref.watch(loggerProvider);
  final cacheOptionsAsync = ref.watch(cacheOptionsProvider);
  final cacheOptions = cacheOptionsAsync.maybeWhen(data: (d) => d, orElse: () => null);
  final dio = DioFactory.createBase(logger: logger, cacheOptions: cacheOptions);
  dio.interceptors.add(OfflineInterceptor(ref.watch(networkInfoProvider)));
  return dio;
});

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(unauthenticatedDioProvider);
  return AuthApi(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(api: api, storage: storage);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(
    repo,
    biometricService: ref.watch(biometricAuthServiceProvider),
    biometricEnabled: () async => ref.read(biometricEnabledProvider).value ?? false,
    snackbar: ref.watch(snackbarServiceProvider),
  );

  // Kick off auto-login as soon as provider is created.
  notifier.ensureInitialized();
  return notifier;
});

final authenticatedDioProvider = Provider<Dio>((ref) {
  final logger = ref.watch(loggerProvider);
  final cacheOptionsAsync = ref.watch(cacheOptionsProvider);
  final cacheOptions = cacheOptionsAsync.maybeWhen(data: (d) => d, orElse: () => null);

  final dio = DioFactory.createBase(logger: logger, cacheOptions: cacheOptions);
  dio.interceptors.add(OfflineInterceptor(ref.watch(networkInfoProvider)));
  final notifier = ref.read(authNotifierProvider.notifier);

  dio.interceptors.add(
    DioFactory.authInterceptor(
      getAccessToken: () async {
        final s = ref.read(authNotifierProvider);
        return s.tokens?.accessToken;
      },
    ),
  );

  dio.interceptors.add(
    DioFactory.refreshOn401Interceptor(
      refresh: () async {
        final tokens = await notifier.refreshTokens();
        return AuthTokenRefreshResult(tokens: tokens);
      },
      onRefreshFailedLogout: () async {
        await notifier.logout();
      },
      dioForRetry: dio,
    ),
  );

  return dio;
});
