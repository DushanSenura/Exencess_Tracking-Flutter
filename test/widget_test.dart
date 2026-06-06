// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenso/app.dart';

void main() {
  testWidgets('Login then show finance navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinanceTrackerApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Expenso'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });
}
