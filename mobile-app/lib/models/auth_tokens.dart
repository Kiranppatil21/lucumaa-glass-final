class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = _findString(json, const [
          'access_token',
          'accessToken',
          'token',
          'jwt',
        ]) ??
        _findNestedString(json, const ['data', 'access_token']) ??
        _findNestedString(json, const ['data', 'token']) ??
        '';

    return AuthTokens(
      accessToken: access,
      refreshToken: _findString(json, const ['refresh_token', 'refreshToken']),
      expiresAt: _parseExpiry(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt?.toIso8601String(),
      };

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp.subtract(const Duration(seconds: 30)));
  }

  static DateTime? _parseExpiry(Map<String, dynamic> json) {
    final expRaw = json['expires_at'] ?? json['expiresAt'] ?? json['expires_in'] ?? json['expiresIn'];
    if (expRaw == null) return null;
    if (expRaw is num) {
      return DateTime.now().add(Duration(seconds: expRaw.toInt()));
    }
    final s = expRaw.toString();
    return DateTime.tryParse(s);
  }

  static String? _findString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _findNestedString(Map<String, dynamic> json, List<String> path) {
    dynamic cur = json;
    for (final segment in path) {
      if (cur is Map<String, dynamic>) {
        cur = cur[segment];
      } else if (cur is Map) {
        cur = cur[segment];
      } else {
        return null;
      }
    }
    if (cur == null) return null;
    final s = cur.toString();
    return s.isEmpty ? null : s;
  }
}
