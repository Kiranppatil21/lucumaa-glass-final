import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class HrEmployeeManagementScreen extends StatelessWidget {
  const HrEmployeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      body: const ComingSoon(title: 'HR • Employee Management'),
    );
  }
}
