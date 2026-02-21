import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: const ComingSoon(title: 'Admin • Manage Users'),
    );
  }
}
