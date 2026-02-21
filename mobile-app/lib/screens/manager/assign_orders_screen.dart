import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class AssignOrdersScreen extends StatelessWidget {
  const AssignOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Orders')),
      body: const ComingSoon(title: 'Manager • Assign Orders'),
    );
  }
}
