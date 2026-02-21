import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class SalaryOverviewScreen extends StatelessWidget {
  const SalaryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Overview')),
      body: const ComingSoon(title: 'HR • Salary Overview'),
    );
  }
}
