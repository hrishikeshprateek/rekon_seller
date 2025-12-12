import 'package:flutter/material.dart';

class OrderBookPage extends StatelessWidget {
  const OrderBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Book')),
      body: const Center(child: Text('Order Book page (empty)')),
    );
  }
}

