import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'user_state_service.dart';

class TutorialService {
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
}

