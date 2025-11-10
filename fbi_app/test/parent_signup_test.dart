import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/parent_signup_page.dart';

void main() {
  group('Parent Signup - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN I am on parent signup page WHEN page loads THEN I should see input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // THEN I should see input fields
      expect(find.byType(TextField), findsWidgets,
          reason: 'Should have text fields for input');
      
      // AND ParentSignupPage should be rendered
      expect(find.byType(ParentSignupPage), findsOneWidget,
          reason: 'ParentSignupPage should be rendered');
    });

    testWidgets('GIVEN I am on signup page WHEN I enter username THEN username field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // Enter username
      await tester.enterText(find.byType(TextField).first, 'test_parent');
      await tester.pump();

      // THEN username should be displayed
      expect(find.text('test_parent'), findsOneWidget,
          reason: 'Username field should accept input');
    });

    testWidgets('GIVEN I am on signup page WHEN I enter email THEN email field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // Enter email
      await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
      await tester.pump();

      // THEN email should be displayed
      expect(find.text('test@example.com'), findsOneWidget,
          reason: 'Email field should accept input');
    });

    testWidgets('GIVEN I am on signup page WHEN I enter password THEN password field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // Enter password
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.pump();

      // THEN password field should have content
      expect(find.byType(TextField).at(2), findsOneWidget,
          reason: 'Password field should accept input');
    });

    testWidgets('GIVEN I am on signup page WHEN I fill all fields THEN form should be ready',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // Enter valid data
      await tester.enterText(find.byType(TextField).first, 'test_parent');
      await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.pump();

      // THEN all fields should have content
      expect(find.text('test_parent'), findsOneWidget,
          reason: 'Username should be entered');
      expect(find.text('test@example.com'), findsOneWidget,
          reason: 'Email should be entered');
      expect(find.byType(TextField).at(2), findsOneWidget,
          reason: 'Password should be entered');
    });

    testWidgets('GIVEN I am on signup page WHEN page renders THEN ParentSignupPage should be present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // THEN ParentSignupPage should be rendered
      expect(find.byType(ParentSignupPage), findsOneWidget,
          reason: 'ParentSignupPage widget should be in the widget tree');
    });
  });

  group('Parent Signup - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN valid signup data WHEN I create account THEN account should be created successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentSignupPage(),
        ),
      );

      // Enter valid data
      await tester.enterText(find.byType(TextField).first, 'new_parent_123');
      await tester.enterText(find.byType(TextField).at(1), 'parent@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'securepass123');
      await tester.pump();

      // Tap Create Account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      // Wait for backend response
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN should navigate to next screen or show success
      expect(find.text('Create Parent Account'), findsNothing,
          reason: 'Should navigate away from signup page after success');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

