// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reckon_seller_2_0/main.dart';

void main() {
  testWidgets('App builds (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Pump a bit more to allow any initial frames/async builders to settle.
    await tester.pump(const Duration(milliseconds: 200));

    // We only assert that the app builds without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
