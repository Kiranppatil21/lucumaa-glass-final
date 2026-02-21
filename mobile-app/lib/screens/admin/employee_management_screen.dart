import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class EmployeeManagementScreen extends StatelessWidget {
  const EmployeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      body: const ComingSoon(title: 'Admin • Employee Management'),
    );
  }
}
