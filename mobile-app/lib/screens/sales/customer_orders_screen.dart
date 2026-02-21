import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Orders')),
      body: const ComingSoon(title: 'Sales • View Customer Orders'),
    );
  }
}
