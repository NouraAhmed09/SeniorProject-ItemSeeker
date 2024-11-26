import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    // Connect to the Flutter application.
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    // Close the connection.
    if (driver != null) {
      await driver.close();
    }
  });

  test('Log in with valid credentials', () async {
    // Find elements using their keys.
    final emailField = find.byValueKey('emailField');
    final passwordField = find.byValueKey('passwordField');
    final signInButton = find.byValueKey('signInButton');

    // Perform actions.
    await driver.tap(emailField);
    await driver.enterText('test@example.com');

    await driver.tap(passwordField);
    await driver.enterText('password123');

    await driver.tap(signInButton);

    // Verify navigation to the home screen.
    final homeScreenText = find.text('Welcome');
    expect(await driver.getText(homeScreenText), 'Welcome');
  });
}
