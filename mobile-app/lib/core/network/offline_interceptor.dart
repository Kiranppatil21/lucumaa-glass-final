import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'network_info.dart';

/// Blocks mutating requests when offline, while allowing GET requests to continue
/// so Dio Cache Interceptor can serve cached responses on network errors.
class OfflineInterceptor extends Interceptor {
  OfflineInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final online = await _networkInfo.isOnline();
    if (online) {
      handler.next(options);
      return;
    }

    final method = options.method.toUpperCase();
    if (method == 'GET') {
      handler.next(options);
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const OfflineException('No internet connection'),
      ),
    );
  }
}
