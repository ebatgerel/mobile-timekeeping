import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_timekeeping_app/main.dart';

void main() {
  testWidgets('shows role selection buttons', (tester) async {
    await tester.pumpWidget(const MobileTimekeepingApp());
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.byIcon(Icons.manage_accounts), findsOneWidget);
    expect(find.byIcon(Icons.engineering), findsOneWidget);
  });
}
