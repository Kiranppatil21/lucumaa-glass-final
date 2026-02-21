import 'package:flutter/material.dart';

class SnackbarService {
  SnackbarService(this.messengerKey);

  final GlobalKey<ScaffoldMessengerState> messengerKey;

  void showMessage(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
