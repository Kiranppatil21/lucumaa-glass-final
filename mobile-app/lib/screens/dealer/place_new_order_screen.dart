import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class PlaceNewOrderScreen extends StatelessWidget {
  const PlaceNewOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place New Order')),
      body: const ComingSoon(title: 'Dealer • Place New Order'),
    );
  }
}
