import 'package:flutter/services.dart';

class ScreenProtector {
  static const MethodChannel _channel = MethodChannel('lucumaa_glass/security');

  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (_) {
      // No-op: native not configured yet.
    }
  }

  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (_) {
      // No-op: native not configured yet.
    }
  }
}
