import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // In production, forward to your crash reporting tool.
  };

  await runZonedGuarded(() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase config may not be present in dev environments.
    }

    runApp(
      const ProviderScope(
        child: LucumaaErpApp(),
      ),
    );
  }, (error, stack) {
    // In production, forward to your crash reporting tool.
  });
}

