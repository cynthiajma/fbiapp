import 'package:fluttermoji/fluttermojiFunctions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarStorageService {
  static const _keyPrefix = 'child_avatar_';

  static Future<void> saveAvatarOptions(String childId, String optionsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$childId', optionsJson);
  }

  static Future<String?> getAvatarSvg(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = prefs.getString('$_keyPrefix$childId');
    if (optionsJson == null || optionsJson.isEmpty) return null;
    return FluttermojiFunctions().decodeFluttermojifromString(optionsJson);
  }
}

