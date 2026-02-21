import 'package:flutter/material.dart';

import '../../widgets/coming_soon.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: const ComingSoon(title: 'Dealer • Payment History'),
    );
  }
}
