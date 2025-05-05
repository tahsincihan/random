import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/login_screen.dart';

void main() {
  testWidgets('Sign in page loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(LoginScreen());

    // Verify that the "Sign in" title appears.
    expect(find.text('Sign in'), findsOneWidget);

    // Verify that the email and password text fields are present.
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify that the "Log In" button is present.
    expect(find.text('Log In'), findsOneWidget);

    // Verify that the "Forgot your password?" link is present.
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('Interact with email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(LoginScreen());

    // Enter text in the email field.
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    expect(find.text('test@example.com'), findsOneWidget);

    // Enter text in the password field.
    await tester.enterText(find.byType(TextField).last, 'password123');
    expect(find.text('password123'), findsOneWidget);
  });

  testWidgets('Tap on "Log In" button', (WidgetTester tester) async {
    await tester.pumpWidget(LoginScreen());

    // Tap the "Log In" button.
    await tester.tap(find.text('Log In'));
    await tester.pump();

    // Verify any additional behavior if required after tapping Log In.
  });
}
