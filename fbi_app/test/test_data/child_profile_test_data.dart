/// Test data for child profile tests
/// Contains mock data for child profiles, logs, and character library

class ChildProfileTestData {
  // Base child profile
  static Map<String, dynamic> baseChildProfile({
    String id = 'test_child_123',
    String username = 'alice_child',
    int age = 8,
  }) {
    return {
      'id': id,
      'username': username,
      'age': age,
    };
  }

  // Character library entries
  static Map<String, dynamic> characterHenryHeartbeat() {
    return {
      'id': '1',
      'name': 'Henry the Heartbeat',
      'photo': null,
      'description': 'Heart character',
      'audio': null,
    };
  }

  static Map<String, dynamic> characterSamanthaSweat() {
    return {
      'id': '2',
      'name': 'Samantha Sweat',
      'photo': null,
      'description': 'Sweat character',
      'audio': null,
    };
  }

  static Map<String, dynamic> characterGassyGus() {
    return {
      'id': '3',
      'name': 'Gassy Gus',
      'photo': null,
      'description': 'Gas character',
      'audio': null,
    };
  }

  static List<Map<String, dynamic>> minimalCharacterLibrary() {
    return [characterHenryHeartbeat()];
  }

  static List<Map<String, dynamic>> multipleCharacterLibrary() {
    return [
      characterHenryHeartbeat(),
      characterSamanthaSweat(),
      characterGassyGus(),
    ];
  }

  // Test scenarios for stats calculations

  /// Zero investigations - empty logs
  static Map<String, dynamic> zeroInvestigations() {
    return {
      'childProfile': baseChildProfile(),
      'childLogs': <Map<String, dynamic>>[],
      'characterLibrary': minimalCharacterLibrary(),
      'expectedInvestigations': 0,
      'expectedStars': 0,
    };
  }

  /// Single investigation at level 7
  static Map<String, dynamic> singleInvestigation() {
    final now = DateTime.now();
    return {
      'childProfile': baseChildProfile(),
      'childLogs': [
        {
          'id': 'log_1',
          'childId': 'test_child_123',
          'characterId': '1',
          'characterName': 'Henry the Heartbeat',
          'level': 7,
          'timestamp': now.toIso8601String(),
          'investigation': <String>[],
        },
      ],
      'characterLibrary': minimalCharacterLibrary(),
      'expectedInvestigations': 1,
      'expectedStars': 7,
    };
  }

  /// Multiple investigations with different characters and levels
  /// Expected: 3 investigations, 16 stars (5 + 8 + 3)
  static Map<String, dynamic> multipleInvestigationsDifferentLevels() {
    final now = DateTime.now();
    return {
      'childProfile': baseChildProfile(),
      'childLogs': [
        {
          'id': 'log_1',
          'childId': 'test_child_123',
          'characterId': '1',
          'characterName': 'Henry the Heartbeat',
          'level': 5,
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
          'investigation': <String>[],
        },
        {
          'id': 'log_2',
          'childId': 'test_child_123',
          'characterId': '2',
          'characterName': 'Samantha Sweat',
          'level': 8,
          'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
          'investigation': <String>[],
        },
        {
          'id': 'log_3',
          'childId': 'test_child_123',
          'characterId': '3',
          'characterName': 'Gassy Gus',
          'level': 3,
          'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
          'investigation': <String>[],
        },
      ],
      'characterLibrary': multipleCharacterLibrary(),
      'expectedInvestigations': 3,
      'expectedStars': 16, // 5 + 8 + 3
    };
  }

  /// Multiple investigations for same character with different levels
  /// Expected: 3 investigations (one per log entry), 21 stars (5 + 7 + 9)
  static Map<String, dynamic> multipleInvestigationsSameCharacter() {
    final now = DateTime.now();
    return {
      'childProfile': baseChildProfile(),
      'childLogs': [
        {
          'id': 'log_1',
          'childId': 'test_child_123',
          'characterId': '1',
          'characterName': 'Henry the Heartbeat',
          'level': 5,
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
          'investigation': <String>[],
        },
        {
          'id': 'log_2',
          'childId': 'test_child_123',
          'characterId': '1',
          'characterName': 'Henry the Heartbeat',
          'level': 7,
          'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
          'investigation': <String>[],
        },
        {
          'id': 'log_3',
          'childId': 'test_child_123',
          'characterId': '2',
          'characterName': 'Samantha Sweat',
          'level': 9,
          'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
          'investigation': <String>[],
        },
      ],
      'characterLibrary': [
        characterHenryHeartbeat(),
        characterSamanthaSweat(),
      ],
      'expectedInvestigations': 3,
      'expectedStars': 21, // 5 + 7 + 9
    };
  }

  // Helper to create a log entry
  static Map<String, dynamic> createLog({
    required String id,
    required String childId,
    required String characterId,
    required String characterName,
    required int level,
    required DateTime timestamp,
    List<String> investigation = const [],
  }) {
    return {
      'id': id,
      'childId': childId,
      'characterId': characterId,
      'characterName': characterName,
      'level': level,
      'timestamp': timestamp.toIso8601String(),
      'investigation': investigation,
    };
  }
}

