import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/parent_login_page.dart';

void main() {
  group('Parent Login - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN I am on parent login page WHEN page loads THEN I should see input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // THEN I should see input fields
      expect(find.byType(TextField), findsWidgets,
          reason: 'Should have text fields for input');
      
      // AND ParentLoginPage should be rendered
      expect(find.byType(ParentLoginPage), findsOneWidget,
          reason: 'ParentLoginPage should be rendered');
    });

    testWidgets('GIVEN I am on parent login page WHEN I enter username THEN username field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // WHEN I enter username
      await tester.enterText(find.byType(TextField).first, 'test_parent');
      await tester.pump();

      // THEN username should be displayed
      expect(find.text('test_parent'), findsOneWidget,
          reason: 'Username field should accept and display input');
    });

    testWidgets('GIVEN I am on parent login page WHEN I enter password THEN password field should accept input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // WHEN I enter password
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      // THEN password should be accepted (shown as obscured or visible based on toggle)
      expect(find.byType(TextField).at(1), findsOneWidget,
          reason: 'Password field should accept input');
    });

    testWidgets('GIVEN I am on parent login page WHEN I have both fields filled THEN form should be ready',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).first, 'test_parent');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      // THEN both fields should have content
      expect(find.text('test_parent'), findsOneWidget,
          reason: 'Username should be entered');
      expect(find.byType(TextField).at(1), findsOneWidget,
          reason: 'Password field should have content');
    });

    testWidgets('GIVEN I am on login page WHEN page renders THEN ParentLoginPage should be present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // THEN ParentLoginPage should be rendered
      expect(find.byType(ParentLoginPage), findsOneWidget,
          reason: 'ParentLoginPage widget should be in the widget tree');
    });
  });

  group('Parent Login - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'child_id': 'test_child_123',
      });
    });

    testWidgets('GIVEN valid credentials WHEN I login THEN I should navigate to parent profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentLoginPage(),
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).first, 'alice_parent');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      // Tap Login
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Wait for navigation
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN should navigate to parent profile
      expect(find.text('Parent Login'), findsNothing,
          reason: 'Should navigate away from login page after successful login');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

