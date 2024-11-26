import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_app/screens/login_screen.dart';

void main() {
  testWidgets('Test login screen functionality without backend', (WidgetTester tester) async {
    // ضخ صفحة تسجيل الدخول
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // العثور على الحقول والأزرار
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final signInButton = find.byKey(const Key('signInButton'));

    // التأكد من وجود الحقول
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(signInButton, findsOneWidget);

    // إدخال البيانات
    await tester.enterText(emailField, 'darin@gmail.com');
    await tester.enterText(passwordField, '123456788');

    // النقر على زر تسجيل الدخول
    await tester.tap(signInButton);

    // انتظار التحديثات
    await tester.pump();

    // التحقق من عدم ظهور أي رسائل خطأ في الواجهة
    expect(find.text('Invalid login credentials'), findsNothing);
  });
}
