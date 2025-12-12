import 'package:flutter/material.dart';

class OutstandingPage extends StatelessWidget {
  const OutstandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding')),
      body: const Center(child: Text('Outstanding page (empty)')),
    );
  }
}

