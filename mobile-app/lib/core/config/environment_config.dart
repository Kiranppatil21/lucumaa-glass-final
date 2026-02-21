/// Environment configuration loaded via compile-time dart defines.
///
/// Build examples:
/// - Dev:     `flutter run --dart-define=APP_ENV=dev`
/// - Staging: `flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.example.com/api`
/// - Prod:    `flutter run --dart-define=APP_ENV=prod`
enum AppEnvironment { dev, staging, prod }

class EnvironmentConfig {
  static const String _envRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static AppEnvironment get current {
    final e = _envRaw.trim().toLowerCase();
    return switch (e) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }

  static String get apiBaseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    // Default to live API unless overridden.
    return switch (current) {
      AppEnvironment.dev => 'https://lucumaaglass.in/api',
      AppEnvironment.staging => 'https://lucumaaglass.in/api',
      AppEnvironment.prod => 'https://lucumaaglass.in/api',
    };
  }
}
