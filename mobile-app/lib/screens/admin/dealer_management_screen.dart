import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class DealerManagementScreen extends StatelessWidget {
  const DealerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dealer Management')),
      body: const ComingSoon(title: 'Admin • Dealer Management'),
    );
  }
}
