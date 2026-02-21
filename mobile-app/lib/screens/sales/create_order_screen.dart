import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: const ComingSoon(title: 'Sales • Create Order'),
    );
  }
}
