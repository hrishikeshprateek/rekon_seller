import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('NOTIFICATION'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 46, color: Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Coming soon...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
      ),
    );
  }
}
