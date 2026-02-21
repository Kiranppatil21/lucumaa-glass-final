import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class TeamOverviewScreen extends StatelessWidget {
  const TeamOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Overview')),
      body: const ComingSoon(title: 'Manager • Team Overview'),
    );
  }
}
