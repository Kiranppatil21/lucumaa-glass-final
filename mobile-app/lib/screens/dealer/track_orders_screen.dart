import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class TrackOrdersScreen extends StatelessWidget {
  const TrackOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Orders')),
      body: const ComingSoon(title: 'Dealer • Track Orders'),
    );
  }
}
