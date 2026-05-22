import 'package:flutter/material.dart';

class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ORDER STATUS'),
      ),
      body: const Center(child: Text('Order Status page (empty)')),
    );
  }
}

