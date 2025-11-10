import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fbi_app/pages/parent_profile.dart';

void main() {
  group('Parent Profile - UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'parent_id': 'test_parent_123',
        'child_id': 'test_child_123',
        'child_name': 'alice_child',
      });
    });

    testWidgets('GIVEN I am on parent profile page WHEN it renders THEN ParentProfilePage widget should exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
        ),
      );

      // THEN ParentProfilePage should be rendered
      expect(find.byType(ParentProfilePage), findsOneWidget,
          reason: 'ParentProfilePage widget should be in the widget tree');
    });

    testWidgets('GIVEN no child ID stored WHEN parent profile page loads THEN I should see error message',
        (WidgetTester tester) async {
      // Set up shared preferences without child_id
      SharedPreferences.setMockInitialValues({
        'parent_id': 'test_parent_123',
      });
      
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
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

    testWidgets('GIVEN I am on parent profile page WHEN page loads THEN I should see ParentProfilePage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // THEN ParentProfilePage should be present
      expect(find.byType(ParentProfilePage), findsOneWidget,
          reason: 'ParentProfilePage should be displayed');
    });
  });

  group('Parent Profile - Integration Tests (Requires Backend)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'parent_id': 'test_parent_123',
        'child_id': 'test_child_123',
        'child_name': 'alice_child',
      });
    });

    testWidgets('GIVEN I am logged in as parent WHEN I navigate to profile THEN I should see child name and data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
        ),
      );

      // Wait for data to load from backend
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // THEN I should see my parent profile page
      expect(find.byType(ParentProfilePage), findsOneWidget,
          reason: 'Should be on ParentProfilePage');
      
      // AND child name should be shown
      expect(find.text('alice_child'), findsOneWidget,
          reason: 'Child name should be displayed');
      
      // AND I should see action buttons
      expect(find.text('Link Another Child'), findsOneWidget,
          reason: 'Link Another Child button should be visible');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN I am on parent profile WHEN I tap Link Another Child button THEN dialog should appear',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // WHEN I tap the Link Another Child button
      await tester.tap(find.text('Link Another Child'));
      await tester.pumpAndSettle();

      // THEN I should see the link dialog
      expect(find.text('Link a Child'), findsOneWidget,
          reason: 'Link a Child dialog should appear');
      
      // AND I should see Cancel and Link buttons
      expect(find.text('Cancel'), findsOneWidget,
          reason: 'Cancel button should be visible in dialog');
      expect(find.text('Link'), findsOneWidget,
          reason: 'Link button should be visible in dialog');
    },
    skip: true,
    tags: ['integration'],
    );

    testWidgets('GIVEN I am on parent profile WHEN I tap Add Parent button THEN dialog should appear',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentProfilePage(),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // WHEN I tap the Add Parent button
      final addParentButton = find.text('Add Parent');
      if (addParentButton.evaluate().isNotEmpty) {
        await tester.tap(addParentButton);
        await tester.pumpAndSettle();

        // THEN I should see the add parent dialog
        expect(find.textContaining('Add Parent to'), findsOneWidget,
            reason: 'Add Parent dialog should appear');
        
        // AND I should see action buttons
        expect(find.text('Cancel'), findsOneWidget,
            reason: 'Cancel button should be visible');
        expect(find.text('Login'), findsOneWidget,
            reason: 'Login button should be visible');
        expect(find.text('Create Account'), findsOneWidget,
            reason: 'Create Account button should be visible');
      }
    },
    skip: true,
    tags: ['integration'],
    );
  });
}

