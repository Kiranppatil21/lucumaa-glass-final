import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Report')),
      body: const ComingSoon(title: 'Sales • Sales Report'),
    );
  }
}
