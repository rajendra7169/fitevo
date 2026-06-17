import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitevo/main.dart';

void main() {
  testWidgets('App boots to home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const FitevoApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
