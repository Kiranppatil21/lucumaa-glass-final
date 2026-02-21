import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class UpdateOrderStatusScreen extends StatelessWidget {
  const UpdateOrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Order Status')),
      body: const ComingSoon(title: 'Operator • Update Order Status'),
    );
  }
}
