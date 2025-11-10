import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/child_signup_page.dart';

void main() {
  group('Child Signup - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN I am on child signup page WHEN page loads THEN I should see input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildSignupPage(),
        ),
      );

      // THEN I should see input fields
      expect(find.byType(TextField), findsWidgets,
          reason: 'Should have text fields for input');
      
      // AND I should see ChildSignupPage
      expect(find.byType(ChildSignupPage), findsOneWidget,
          reason: 'ChildSignupPage should be rendered');
    });

    testWidgets('GIVEN I am on signup page WHEN I enter username THEN username field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildSignupPage(),
        ),
      );

      // WHEN I enter a valid username
      await tester.enterText(find.byType(TextField).first, 'test_child');
      await tester.pump();

      // THEN username should be displayed
      expect(find.text('test_child'), findsOneWidget,
          reason: 'Username field should accept and display input');
    });

    testWidgets('GIVEN I am on signup page WHEN I enter age THEN age field should accept numbers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildSignupPage(),
        ),
      );

      // WHEN I enter an age
      final ageField = find.byType(TextField).at(1);
      await tester.enterText(ageField, '8');
      await tester.pump();

      // THEN age should be displayed
      expect(find.text('8'), findsOneWidget,
          reason: 'Age field should accept and display numeric input');
    });

    testWidgets('GIVEN I am on signup page WHEN page renders THEN ChildSignupPage should be present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildSignupPage(),
        ),
      );

      // THEN ChildSignupPage should be rendered
      expect(find.byType(ChildSignupPage), findsOneWidget,
          reason: 'ChildSignupPage widget should be in the widget tree');
    });
  });

  group('Child Signup - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN valid username WHEN I create account THEN I should see parent linking dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildSignupPage(),
        ),
      );

      // Enter valid data
      await tester.enterText(find.byType(TextField).first, 'new_test_child');
      await tester.enterText(find.byType(TextField).at(1), '10');
      await tester.pump();

      // Tap Create Account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      // Wait for backend response
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN parent linking dialog should appear
      expect(find.text('Create Parent Account'), findsOneWidget,
          reason: 'Parent linking dialog should appear after successful signup');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

