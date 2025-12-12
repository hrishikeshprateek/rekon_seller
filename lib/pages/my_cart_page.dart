import 'package:flutter/material.dart';

class MyCartPage extends StatelessWidget {
  const MyCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: const Center(child: Text('My Cart page (empty)')),
    );
  }
}

