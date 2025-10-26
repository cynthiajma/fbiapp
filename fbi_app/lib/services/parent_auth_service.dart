import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

class ParentAuthService {
  static const String _loginParentMutation = '''
    mutation LoginParent(\$username: String!, \$password: String!) {
      loginParent(username: \$username, password: \$password) {
        id
        username
      }
    }
  ''';

  static const String _linkParentChildMutation = '''
    mutation LinkParentChild(\$parentId: ID!, \$childId: ID!) {
      linkParentChild(parentId: \$parentId, childId: \$childId)
    }
  ''';

  static const String _getParentChildrenQuery = '''
    query GetParentChildren(\$parentId: ID!) {
      parentProfile(id: \$parentId) {
        id
        username
        children {
          id
          username
          name
          age
        }
      }
    }
  ''';

  /// Login parent with username and password
  static Future<Map<String, dynamic>?> loginParent(String username, String password, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.mutate(
        MutationOptions(
          document: gql(_loginParentMutation),
          variables: {
            'username': username,
            'password': password,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['loginParent'];
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Link parent to child
  static Future<bool> linkParentChild(String parentId, String childId, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.mutate(
        MutationOptions(
          document: gql(_linkParentChildMutation),
          variables: {
            'parentId': parentId,
            'childId': childId,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['linkParentChild'] ?? false;
    } catch (e) {
      throw Exception('Failed to link parent and child: $e');
    }
  }

  /// Get parent's children
  static Future<List<Map<String, dynamic>>> getParentChildren(String parentId, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getParentChildrenQuery),
          variables: {
            'parentId': parentId,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final children = result.data?['parentProfile']?['children'] as List<dynamic>?;
      return children?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to get parent children: $e');
    }
  }
}
