import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_app/main.dart';

void main() {
  testWidgets('Verify App Title and Main Screen', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(MyApp());

    // Verify the app title
    expect(find.text('Seeker App'), findsOneWidget);

    // Verify a widget in the main screen
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
