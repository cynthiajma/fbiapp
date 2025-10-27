import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ChildAuthService {
  static const String _getChildByUsernameQuery = '''
    query GetChildByUsername(\$username: String!) {
      childByUsername(username: \$username) {
        id
        username
        name
        age
      }
    }
  ''';

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
}

