import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../services/storage/secure_storage_service.dart';
import '../../services/notifications/push_notifications_service.dart';
import '../network/network_info.dart';
import '../ui/snackbar_service.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage);
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  return PushNotificationsService(messaging);
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfo(connectivity);
});

final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});

final snackbarServiceProvider = Provider<SnackbarService>((ref) {
  return SnackbarService(ref.watch(scaffoldMessengerKeyProvider));
});


