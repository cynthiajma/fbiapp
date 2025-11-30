import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ChildAuthService {
  static const String _createChildMutation = '''
    mutation CreateChild(\$username: String!, \$age: Int) {
      createChild(username: \$username, age: \$age) {
        id
        username
        age
      }
    }
  ''';
  static const String _getChildByUsernameQuery = '''
    query GetChildByUsername(\$username: String!) {
      childByUsername(username: \$username) {
        id
        username
        age
      }
    }
  ''';

  static const String _getChildByIdQuery = '''
    query GetChildProfile(\$id: ID!) {
      childProfile(id: \$id) {
        id
        username
        age
      }
    }
  ''';

  /// Get child by ID
  static Future<Map<String, dynamic>?> getChildById(
    String id,
    BuildContext context,
  ) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getChildByIdQuery),
          variables: {
            'id': id,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['childProfile'];
    } catch (e) {
      throw Exception('Failed to get child by ID: $e');
    }
  }

  /// Get child by username for login verification
  static Future<Map<String, dynamic>?> getChildByUsername(
    String username,
    BuildContext context,
  ) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getChildByUsernameQuery),
          variables: {
            'username': username,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['childByUsername'];
    } catch (e) {
      throw Exception('Failed to verify child username: $e');
    }
  }

  /// Create a new child profile
  static Future<Map<String, dynamic>?> createChild({
    required String username,
    int? age,
    required BuildContext context,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;

      final result = await client.mutate(
        MutationOptions(
          document: gql(_createChildMutation),
          variables: {
            'username': username,
            'age': age,
          },
        ),
      );

      if (result.hasException) {
        // Extract the clean error message from GraphQL response
        String errorMessage = 'Failed to create child account';
        if (result.exception != null) {
          final errorString = result.exception.toString();
          
          // Check for duplicate username error first
          final lowerError = errorString.toLowerCase();
          if (lowerError.contains('duplicate username') || 
              lowerError.contains('already taken') ||
              lowerError.contains('unique constraint') ||
              lowerError.contains('23505')) {
            errorMessage = 'This detective name is already taken. Please choose a different name.';
          } else {
            // Try to extract from GraphQLError format
            final graphqlMatch = RegExp(r'message:\s*"([^"]+)"').firstMatch(errorString);
            if (graphqlMatch != null) {
              errorMessage = graphqlMatch.group(1)!;
            } else {
              // Try to extract message: ... 
              final messageMatch = RegExp(r'message:\s*([^\n,]+)').firstMatch(errorString);
              if (messageMatch != null) {
                errorMessage = messageMatch.group(1)!.trim()
                  .replaceAll('"', '')
                  .replaceAll("'", '');
              } else {
                // Fallback: remove common prefixes
                errorMessage = errorString
                    .replaceAll(RegExp(r'^(Exception|Error|GraphQLError|LinkException):\s*'), '')
                    .split('\n')
                    .first
                    .trim();
              }
            }
          }
        }
        throw Exception(errorMessage);
      }

      return result.data?['createChild'];
    } catch (e) {
      // If it's already our formatted error, re-throw it
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
      if (errorMsg.contains('Duplicate username')) {
        throw Exception(errorMsg);
      }
      throw Exception('Failed to create child: $errorMsg');
    }
  }
}

