import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class LoggingService {
  static const String logFeelingMutation = '''
    mutation LogFeeling(\$childId: ID!, \$characterId: ID!, \$level: Int!, \$investigation: [String!]) {
      logFeeling(childId: \$childId, characterId: \$characterId, level: \$level, investigation: \$investigation) {
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

  /// Log a feeling with optional investigation
  /// 
  /// - [childId]: The ID of the child logging the feeling
  /// - [characterId]: The ID of the character they're feeling about
  /// - [level]: The feeling level (0-10)
  /// - [investigation]: Optional list of words describing the feeling
  /// - [context]: BuildContext to access GraphQL client
  static Future<Map<String, dynamic>> logFeeling({
    required String childId,
    required String characterId,
    required int level,
    List<String>? investigation,
    required BuildContext context,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final MutationOptions options = MutationOptions(
        document: gql(logFeelingMutation),
        variables: {
          'childId': childId,
          'characterId': characterId,
          'level': level,
          if (investigation != null) 'investigation': investigation,
        },
      );

      final QueryResult result = await client.mutate(options);

      if (result.hasException) {
        throw Exception('GraphQL Error: ${result.exception}');
      }

      return result.data?['logFeeling'] ?? {};
    } catch (e) {
      throw Exception('Failed to log feeling: $e');
    }
  }
}
