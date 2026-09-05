import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kioku/main.dart';

void main() {
  testWidgets('Kioku brand mark renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: KiokuMark(size: 64))),
      ),
    );
    expect(find.byType(KiokuMark), findsOneWidget);
  });
}
