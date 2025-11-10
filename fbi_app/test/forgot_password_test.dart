import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/forgot_password_page.dart';

void main() {
  group('Forgot Password - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN I am on forgot password page WHEN page loads THEN I should see email form',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // THEN I should see the title
      expect(find.text('FORGOT PASSWORD'), findsOneWidget,
          reason: 'Page title should be visible');
      
      // AND I should see instruction text
      expect(find.text('Enter Your Email'), findsOneWidget,
          reason: 'Email step title should be visible');
      
      // AND I should see email field
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Email input field should be visible');
      
      // AND I should see send button
      expect(find.text('Send Reset Link'), findsOneWidget,
          reason: 'Send Reset Link button should be visible');
      
      // AND I should see back to login link
      expect(find.text('Back to Login'), findsOneWidget,
          reason: 'Back to Login link should be visible');
    });

    testWidgets('GIVEN I am on forgot password page WHEN I enter email THEN email field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // WHEN I enter email
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      // THEN email should be displayed
      expect(find.text('test@example.com'), findsOneWidget,
          reason: 'Email field should accept and display input');
    });

    testWidgets('GIVEN I am on forgot password page WHEN page renders THEN ForgotPasswordPage should be present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // THEN ForgotPasswordPage should be rendered
      expect(find.byType(ForgotPasswordPage), findsOneWidget,
          reason: 'ForgotPasswordPage widget should be in the widget tree');
    });
  });

  group('Forgot Password - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN valid email WHEN I request reset THEN I should see code entry step',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // Enter valid email
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.pump();

      // Tap Send Reset Link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      // Wait for backend response
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see code entry step
      expect(find.text('Check Your Email'), findsOneWidget,
          reason: 'Should move to code entry step after successful email submission');
      
      // AND I should see code input field
      expect(find.byType(TextField), findsWidgets,
          reason: 'Should see code and password fields');
      
      // AND I should see Reset Password button
      expect(find.text('Reset Password'), findsOneWidget,
          reason: 'Reset Password button should be visible');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN I am on code entry step WHEN I enter invalid code THEN I should see error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // First, get to code entry step
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Assume we're now on code entry step
      // Enter invalid code
      final codeField = find.byType(TextField).first;
      await tester.enterText(codeField, '000000');
      
      // Enter password fields
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(1), 'newpass123');
      await tester.enterText(passwordFields.at(2), 'newpass123');
      await tester.pump();

      // Tap Reset Password
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Wait for error
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see error message
      expect(find.textContaining('Invalid'), findsOneWidget,
          reason: 'Should show error for invalid code');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN I am on code entry step WHEN passwords do not match THEN I should see error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // First, get to code entry step
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Enter code
      final codeField = find.byType(TextField).first;
      await tester.enterText(codeField, '123456');
      
      // Enter mismatched passwords
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(1), 'password1');
      await tester.enterText(passwordFields.at(2), 'password2');
      await tester.pump();

      // Tap Reset Password
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // THEN I should see password mismatch error
      expect(find.text('Passwords do not match'), findsOneWidget,
          reason: 'Should show error when passwords do not match');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN valid code and password WHEN I reset password THEN I should see success message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // First, get to code entry step
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Enter valid code (this would be from email in real scenario)
      final codeField = find.byType(TextField).first;
      await tester.enterText(codeField, '123456'); // Replace with actual code from test email
      
      // Enter matching passwords
      final passwordFields = find.byType(TextField);
      await tester.enterText(passwordFields.at(1), 'newpass123');
      await tester.enterText(passwordFields.at(2), 'newpass123');
      await tester.pump();

      // Tap Reset Password
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      // Wait for success
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see success message
      expect(find.text('Password Reset!'), findsOneWidget,
          reason: 'Should show success message after password reset');
      
      // AND I should see success icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget,
          reason: 'Success icon should be visible');
      
      // AND I should see redirect message
      expect(find.text('Redirecting to login...'), findsOneWidget,
          reason: 'Redirect message should be visible');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN I am on code entry step WHEN I tap Resend Code THEN code should be resent',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      // First, get to code entry step
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // WHEN I tap Resend Code
      await tester.tap(find.text('Resend Code'));
      await tester.pump();

      // Wait for resend operation
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should still be on code entry step
      expect(find.text('Check Your Email'), findsOneWidget,
          reason: 'Should remain on code entry step after resending');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

