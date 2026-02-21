import 'environment_config.dart';

class AppConfig {
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  static const String loginPath = '/auth/login';
  // Refresh endpoint not exposed by this backend (keep null behavior).
  static const String refreshPath = '/auth/refresh';
  static const String mePath = '/auth/me';

  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  static const int defaultPageSize = 20;
}

