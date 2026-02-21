import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class ManagerReportsScreen extends StatelessWidget {
  const ManagerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const ComingSoon(title: 'Manager • View Reports'),
    );
  }
}
