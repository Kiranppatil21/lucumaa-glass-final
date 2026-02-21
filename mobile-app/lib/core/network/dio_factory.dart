import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../../models/auth_tokens.dart';
import 'logging_interceptor.dart';

class DioFactory {
  static Dio createBase({required Logger logger, CacheOptions? cacheOptions}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LoggingInterceptor(logger));
    if (cacheOptions != null) {
      dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
    }

    return dio;
  }

  static Interceptor authInterceptor({
    required Future<String?> Function() getAccessToken,
  }) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  static Interceptor refreshOn401Interceptor({
    required Future<AuthTokenRefreshResult> Function() refresh,
    required FutureOr<void> Function() onRefreshFailedLogout,
    required Dio dioForRetry,
  }) {
    return InterceptorsWrapper(
      onError: (err, handler) async {
        final status = err.response?.statusCode;
        final options = err.requestOptions;

        final alreadyRetried = options.extra['__retried'] == true;
        if (status == 401 && !alreadyRetried) {
          options.extra['__retried'] = true;

          final result = await refresh();
          if (result.tokens != null) {
            options.headers['Authorization'] = 'Bearer ${result.tokens!.accessToken}';
            try {
              final response = await dioForRetry.fetch(options);
              return handler.resolve(response);
            } catch (_) {
              // fall through to logout
            }
          }

          await onRefreshFailedLogout();
        }

        handler.next(err);
      },
    );
  }
}

class AuthTokenRefreshResult {
  final Object? error;
  final AuthTokens? tokens;

  const AuthTokenRefreshResult({this.tokens, this.error});
}
