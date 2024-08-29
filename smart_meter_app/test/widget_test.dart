import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_meter_app/main.dart';

void main() {
  testWidgets('Home screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the Home Screen displays the correct title.
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Second Screen'), findsNothing);

    // Tap the 'Go to Second Screen' button and trigger a frame.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify that the Second Screen is now displayed.
    expect(find.text('Home Screen'), findsNothing);
    expect(find.text('Second Screen'), findsOneWidget);
  });
}
