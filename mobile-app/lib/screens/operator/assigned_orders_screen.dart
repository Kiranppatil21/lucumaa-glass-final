import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class AssignedOrdersScreen extends StatelessWidget {
  const AssignedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Orders')),
      body: const ComingSoon(title: 'Operator • View Assigned Orders'),
    );
  }
}
