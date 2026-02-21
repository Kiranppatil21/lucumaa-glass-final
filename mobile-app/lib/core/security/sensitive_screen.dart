import 'package:flutter/material.dart';

import 'screen_protector.dart';

class SensitiveScreen extends StatefulWidget {
  const SensitiveScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SensitiveScreen> createState() => _SensitiveScreenState();
}

class _SensitiveScreenState extends State<SensitiveScreen> {
  @override
  void initState() {
    super.initState();
    ScreenProtector.enableSecure();
  }

  @override
  void dispose() {
    ScreenProtector.disableSecure();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
