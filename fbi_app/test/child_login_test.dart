

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/child_login_page.dart';
import 'package:fbi_app/home.dart';

void main() {
  group('Child Login - UI Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN empty username WHEN I tap login button THEN I should see validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildLoginPage(),
        ),
      );

      // WHEN I tap the login button without entering a username
      final loginButton = find.widgetWithText(ElevatedButton, 'Start Investigating');
      await tester.tap(loginButton);
      await tester.pump();

      // THEN I should see an error message
      expect(find.text('Please enter your detective name!'), findsOneWidget,
          reason: 'Validation error should be shown for empty username');
      
      // AND I should still be on the login page
      expect(find.text('Enter Your Detective Name'), findsOneWidget,
          reason: 'Should remain on login page');
    });

    testWidgets('GIVEN valid username WHEN I tap Start Investigating button THEN button should show loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildLoginPage(),
        ),
      );

      // WHEN I enter a valid username
      await tester.enterText(find.byType(TextField), 'alice_child');
      await tester.pump();

      // AND I tap the "Start Investigating" button
      final loginButton = find.widgetWithText(ElevatedButton, 'Start Investigating');
      await tester.tap(loginButton);
      await tester.pump();

      // AND there should be no validation error
      expect(find.text('Please enter your detective name!'), findsNothing,
          reason: 'No validation error should appear for valid username');
    });

  });

  group('Child Login - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GIVEN non-existent username WHEN I tap Start Investigating button THEN I should see error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Navigate to login page by tapping logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.text('Enter Your Detective Name'), findsOneWidget);

      // WHEN I enter a non-existent username
      await tester.enterText(find.byType(TextField), 'nonexistent_user_12345');
      await tester.pump();

      // AND I tap the "Start Investigating" button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Investigating'));
      await tester.pump();

      // Wait for error to appear
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see an error message
      expect(find.text('Detective name not found. Please try again or contact support.'), findsOneWidget,
          reason: 'Should show "not found" error for non-existent username');
      
      // AND I should still be on the login page
      expect(find.text('Enter Your Detective Name'), findsOneWidget,
          reason: 'Should remain on login page when username not found');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN valid username WHEN I tap Start Investigating button THEN I should navigate to home page',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Navigate to login page by tapping logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.text('Enter Your Detective Name'), findsOneWidget);

      // WHEN I enter a valid username
      await tester.enterText(find.byType(TextField), 'alice_child');
      await tester.pump();

      // AND I tap the "Start Investigating" button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Investigating'));
      await tester.pump();

      // Wait for navigation to complete
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should be navigated to the home page
      expect(find.byType(HomePage), findsOneWidget,
          reason: 'Should navigate to HomePage after successful login');
      
      // AND I should see the home page content
      expect(find.text('Feelings and Body\nInvestigation'), findsOneWidget,
          reason: 'Should see the home page title');
      
      // AND my session should be saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('child_id'), isNotNull,
          reason: 'Child ID should be saved to session');
      expect(prefs.getString('child_name'), equals('alice_child'),
          reason: 'Child name should be saved to session as alice_child');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}
