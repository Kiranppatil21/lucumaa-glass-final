import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const ComingSoon(title: 'HR • Attendance'),
    );
  }
}
