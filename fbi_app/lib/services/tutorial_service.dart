import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'user_state_service.dart';

class TutorialService {
  // Child tutorial keys
  static final GlobalKey _startCaseKey = GlobalKey();
  static final GlobalKey _gamesKey = GlobalKey();
  static final GlobalKey _investigateKey = GlobalKey();
  static final GlobalKey _profileKey = GlobalKey();
  static final GlobalKey _helpIconKey = GlobalKey();

  static GlobalKey get startCaseKey => _startCaseKey;
  static GlobalKey get gamesKey => _gamesKey;
  static GlobalKey get investigateKey => _investigateKey;
  static GlobalKey get profileKey => _profileKey;
  static GlobalKey get helpIconKey => _helpIconKey;

  // Parent tutorial keys
  static final GlobalKey _parentChildListKey = GlobalKey();
  static final GlobalKey _parentAddParentKey = GlobalKey();
  static final GlobalKey _parentHelpIconKey = GlobalKey();
  static final GlobalKey _parentLogoutKey = GlobalKey();

  static GlobalKey get parentChildListKey => _parentChildListKey;
  static GlobalKey get parentAddParentKey => _parentAddParentKey;
  static GlobalKey get parentHelpIconKey => _parentHelpIconKey;
  static GlobalKey get parentLogoutKey => _parentLogoutKey;

  /// Start the tutorial showcase
  static Future<void> startTutorial(BuildContext context) async {
    // Wait a bit for the UI to be fully rendered
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      ShowCaseWidget.of(context).startShowCase([
        _startCaseKey,
        _gamesKey,
        _investigateKey,
        _profileKey,
        _helpIconKey,
      ]);
    }
  }

  /// Check if tutorial should be shown and start it if needed
  static Future<void> checkAndStartTutorial(BuildContext context) async {
    final isCompleted = await UserStateService.isTutorialCompleted();
    if (!isCompleted && context.mounted) {
      await startTutorial(context);
    }
  }

  /// Mark tutorial as completed
  static Future<void> completeTutorial() async {
    await UserStateService.markTutorialCompleted();
  }

  /// Reset and restart tutorial
  static Future<void> resetAndStartTutorial(BuildContext context) async {
    await UserStateService.resetTutorial();
    if (context.mounted) {
      await startTutorial(context);
    }
  }

  // ========== PARENT TUTORIAL METHODS ==========

  /// Start the parent tutorial showcase
  static Future<void> startParentTutorial(BuildContext context) async {
    // Wait a bit for the UI to be fully rendered
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      ShowCaseWidget.of(context).startShowCase([
        _parentChildListKey,
        _parentAddParentKey,
        _parentLogoutKey,
        _parentHelpIconKey,
      ]);
    }
  }

  /// Check if parent tutorial should be shown and start it if needed
  static Future<void> checkAndStartParentTutorial(BuildContext context) async {
    final isCompleted = await UserStateService.isParentTutorialCompleted();
    if (!isCompleted && context.mounted) {
      await startParentTutorial(context);
    }
  }

  /// Mark parent tutorial as completed
  static Future<void> completeParentTutorial() async {
    await UserStateService.markParentTutorialCompleted();
  }

  /// Reset and restart parent tutorial
  static Future<void> resetAndStartParentTutorial(BuildContext context) async {
    await UserStateService.resetParentTutorial();
    if (context.mounted) {
      await startParentTutorial(context);
    }
  }
}

