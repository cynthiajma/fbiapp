import 'package:shared_preferences/shared_preferences.dart';

class UserStateService {
  static const String _childNameKey = 'child_name';
  static const String _childIdKey = 'child_id';
  static const String _parentAuthenticatedKey = 'parent_authenticated';
  static const String _parentIdKey = 'parent_id';
  static const String _tutorialCompletedKey = 'tutorial_completed';
  
  /// Get the current child's name
  static Future<String?> getChildName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childNameKey);
  }
  
  /// Save the child's name
  static Future<void> saveChildName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childNameKey, name);
  }
  
  /// Get the current child's ID
  static Future<String?> getChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childIdKey);
  }
  
  /// Save the child's ID
  static Future<void> saveChildId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childIdKey, id);
  }
  
  /// Check if parent is authenticated
  static Future<bool> isParentAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_parentAuthenticatedKey) ?? false;
  }
  
  /// Save parent authentication state
  static Future<void> saveParentAuthenticated(bool authenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_parentAuthenticatedKey, authenticated);
  }
  
  /// Get the current parent's ID
  static Future<String?> getParentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentIdKey);
  }
  
  /// Save the parent's ID
  static Future<void> saveParentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentIdKey, id);
  }
  
  /// Check if a user is logged in
  static Future<bool> isLoggedIn() async {
    final name = await getChildName();
    return name != null && name.isNotEmpty;
  }
  
  /// Check if tutorial has been completed
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }
  
  /// Mark tutorial as completed
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }
  
  /// Reset tutorial completion (for testing or replay)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
  }
  
  /// Clear tutorial status when clearing user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childNameKey);
    await prefs.remove(_childIdKey);
    await prefs.remove(_parentAuthenticatedKey);
    await prefs.remove(_parentIdKey);
    await prefs.remove(_tutorialCompletedKey);
  }
}
