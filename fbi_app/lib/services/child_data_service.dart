import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

class ChildDataService {
  static const String _getChildProfileQuery = '''
    query GetChildProfile(\$childId: ID!) {
      childProfile(id: \$childId) {
        id
        username
        age
        parents {
          id
          username
        }
      }
    }
  ''';

  static const String _getChildLogsQuery = '''
    query GetChildLogs(\$childId: ID!, \$startTime: String, \$endTime: String) {
      childLogs(childId: \$childId, startTime: \$startTime, endTime: \$endTime) {
        id
        childId
        characterId
        characterName
        level
        timestamp
        investigation
      }
    }
  ''';

  static const String _getCharacterLibraryQuery = '''
    query GetCharacterLibrary {
      characterLibrary {
        id
        name
        photo
        description
        audio
      }
    }
  ''';

  /// Get child profile information
  static Future<Map<String, dynamic>?> getChildProfile(String childId, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getChildProfileQuery),
          variables: {
            'childId': childId,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['childProfile'];
    } catch (e) {
      throw Exception('Failed to get child profile: $e');
    }
  }

  /// Get child's logging data
  static Future<List<Map<String, dynamic>>> getChildLogs(
    String childId,
    BuildContext context, {
    String? startTime,
    String? endTime,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final variables = <String, dynamic>{
        'childId': childId,
      };
      
      if (startTime != null) {
        variables['startTime'] = startTime;
      }
      if (endTime != null) {
        variables['endTime'] = endTime;
      }
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getChildLogsQuery),
          variables: variables,
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final logs = result.data?['childLogs'] as List<dynamic>?;
      return logs?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to get child logs: $e');
    }
  }

  /// Get character library
  static Future<List<Map<String, dynamic>>> getCharacterLibrary(BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getCharacterLibraryQuery),
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final characters = result.data?['characterLibrary'] as List<dynamic>?;
      return characters?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to get character library: $e');
    }
  }

  /// Map character names to image file names
  static String getCharacterImagePath(String characterName) {
    final Map<String, String> nameMapping = {
      'Henry the Heartbeat': 'henry_heartbeat.png',
      'Samantha Sweat': 'samatha_sweat.png',
      'Gassy Gus': 'gassy_gus.png',
      'Betty Butterfly': 'betty_butterfly.png',
      'Gerda Gotta Go': 'gerda_gotta_go.png',
      'Gordon Gotta Go': 'gordon_gotta_go.png',
      'Patricia the Poop Pain': 'patricia_the_poop_pain.png',
      'Polly Pain': 'polly_pain.png',
      'Ricky the Rock': 'ricky_the_rock.png',
      'Heart': 'heart.png',
      'Classified': 'classified.png',
    };
    
    return nameMapping[characterName] ?? 'classified.png';
  }

  /// Process logs to create individual log entries (not averaged)
  static List<Map<String, dynamic>> processLogsToIndividualEntries(
    List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> characters,
  ) {
    // Create a map of character ID to character data for quick lookup
    final Map<String, Map<String, dynamic>> characterMapById = {};
    final Map<String, Map<String, dynamic>> characterMapByName = {};
    
    for (final character in characters) {
      final id = character['id'] as String?;
      final name = character['name'] as String?;
      if (id != null) {
        characterMapById[id] = character;
      }
      if (name != null) {
        characterMapByName[name] = character;
      }
    }

    // Convert each log to a character entry
    final List<Map<String, dynamic>> logEntries = [];
    
    for (final log in logs) {
      // Try to find character by ID first, then by name
      final characterId = log['characterId'] as String?;
      final characterName = log['characterName'] as String?;
      
      Map<String, dynamic>? character;
      String? displayName;
      
      if (characterId != null && characterMapById.containsKey(characterId)) {
        character = characterMapById[characterId];
        displayName = character?['name'] as String? ?? characterName;
      } else if (characterName != null && characterMapByName.containsKey(characterName)) {
        character = characterMapByName[characterName];
        displayName = characterName;
      }
      
      if (character != null && displayName != null) {
        final level = log['level'] as int;
        final timestamp = DateTime.parse(log['timestamp'] as String);
        
        logEntries.add({
          'character': character,
          'characterName': displayName,
          'level': level,
          'progress': level / 10.0, // Convert level (0-10) to progress (0-1)
          'date': timestamp,
          'logId': log['id'],
        });
      }
    }
    
    // Sort by timestamp (most recent first)
    logEntries.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });
    
    return logEntries;
  }
}
