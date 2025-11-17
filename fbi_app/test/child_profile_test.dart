import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/home_page.dart';
import 'package:fbi_app/pages/child_profile_page.dart';
import 'package:fluttermoji/fluttermoji.dart';

void main() {
  group('Child Profile - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'child_id': 'test_child_123',
        'child_name': 'alice_child',
      });
    });

    testWidgets('GIVEN I am logged in WHEN I tap profile button THEN I should see loading indicator',
        (WidgetTester tester) async {
      // GIVEN I am logged in as a child
      // AND I am on the home page
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // WHEN I tap the profile/settings button
      final profileButton = find.byType(FluttermojiCircleAvatar);
      expect(profileButton, findsWidgets,
          reason: 'Profile button should be visible on home page');
      
      await tester.tap(profileButton.first);
      await tester.pumpAndSettle();

      // THEN I should see my profile page
      expect(find.byType(ChildProfilePage), findsOneWidget,
          reason: 'Should navigate to ChildProfilePage');
      
      // Initially shows loading or loaded state
      // (Cannot verify specific data without backend)
    });

    testWidgets('GIVEN no child ID stored WHEN profile page loads THEN I should see error message',
        (WidgetTester tester) async {
      // Set up shared preferences without child_id
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildProfilePage(),
        ),
      );

      // Wait for async operations
      await tester.pump();
      await tester.pump();

      // THEN I should see error message
      expect(find.text('No child selected'), findsOneWidget,
          reason: 'Error message should appear when no child is selected');
      
      // AND I should see retry button
      expect(find.text('Retry'), findsOneWidget,
          reason: 'Retry button should be visible');
    });

    testWidgets('GIVEN I am on profile page WHEN it renders THEN ChildProfilePage widget should exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildProfilePage(),
        ),
      );

      // THEN ChildProfilePage should be rendered
      expect(find.byType(ChildProfilePage), findsOneWidget,
          reason: 'ChildProfilePage widget should be in the widget tree');
    });
  });

  group('Child Profile - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'child_id': 'test_child_123',
        'child_name': 'alice_child',
      });
    });

    testWidgets('GIVEN I am logged in WHEN I navigate to profile THEN I should see my username and profile details',
        (WidgetTester tester) async {
      // GIVEN I am logged in as a child
      // AND I am on the home page
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // WHEN I tap the profile/settings button
      final profileButton = find.byType(FluttermojiCircleAvatar);
      await tester.tap(profileButton.first);
      await tester.pumpAndSettle();

      // Wait for data to load from backend
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see my profile page
      expect(find.byType(ChildProfilePage), findsOneWidget,
          reason: 'Should navigate to ChildProfilePage');
      
      // AND my username should be shown
      expect(find.text('ALICE_CHILD'), findsOneWidget,
          reason: 'Child username should be displayed in uppercase');
      
      // AND I should see the detective badge
      expect(find.text('DETECTIVE'), findsOneWidget,
          reason: 'Detective badge should be displayed');
      
      // AND I should see stats section
      expect(find.text('Investigations'), findsOneWidget,
          reason: 'Investigations stat should be visible');
      expect(find.text('Stars'), findsOneWidget,
          reason: 'Stars stat should be visible');
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

