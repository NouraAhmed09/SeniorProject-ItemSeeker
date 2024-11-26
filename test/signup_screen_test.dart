import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_app/screens/signup_screen.dart';

void main() {
  group('Signup Screen Tests', () {
    testWidgets('UT.1: Signup Validation - Empty Fields', (WidgetTester tester) async {
      // Render the signup screen
      await tester.pumpWidget(const MaterialApp(
        home: SignupScreen(),
      ));

      // Find the signup button and error message
      final signupButton = find.byKey(const Key('signupButton'));
      final errorMessage = find.text('Please fill in all fields');

      // Tap the signup button without entering any data
      await tester.tap(signupButton);
      await tester.pump();

      // Verify that the error message is displayed
      expect(errorMessage, findsOneWidget);
    });

    testWidgets('UT.2: Password Confirmation - Non-Matching Passwords', (WidgetTester tester) async {
      // Render the signup screen
      await tester.pumpWidget(const MaterialApp(
        home: SignupScreen(),
      ));

      // Find the fields and the signup button
      final passwordField = find.byKey(const Key('passwordField'));
      final confirmPasswordField = find.byKey(const Key('confirmPasswordField'));
      final signupButton = find.byKey(const Key('signupButton'));
      final errorMessage = find.text('Passwords do not match.');

      // Enter passwords that do not match
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'password456');
      await tester.tap(signupButton);
      await tester.pump();

      // Verify that the error message is displayed
      expect(errorMessage, findsOneWidget);
    });

    testWidgets('UT.3: Successful Signup - Valid Inputs', (WidgetTester tester) async {
      // Render the signup screen
      await tester.pumpWidget(const MaterialApp(
        home: SignupScreen(),
      ));

      // Find the fields and the signup button
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      final confirmPasswordField = find.byKey(const Key('confirmPasswordField'));
      final signupButton = find.byKey(const Key('signupButton'));

      // Enter valid credentials
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'password123');
      await tester.tap(signupButton);
      await tester.pump();

      // Verify navigation to the login screen
      expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    });
  });
}
