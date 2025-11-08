import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

class ParentDataService {
  static const String _getParentChildrenQuery = '''
    query GetParentChildren(\$parentId: ID!) {
      parentChildren(parentId: \$parentId) {
        id
        username
        name
        age
      }
    }
  ''';

  static const String _linkParentChildMutation = '''
    mutation LinkParentChild(\$parentId: ID!, \$childId: ID!) {
      linkParentChild(parentId: \$parentId, childId: \$childId)
    }
  ''';

  static const String _getChildByUsernamQuery = '''
    query GetChildByUsername(\$username: String!) {
      childByUsername(username: \$username) {
        id
        username
        name
        age
      }
    }
  ''';

  static const String _isParentLinkedToChildQuery = '''
    query IsParentLinkedToChild(\$parentId: ID!, \$childId: ID!) {
      isParentLinkedToChild(parentId: \$parentId, childId: \$childId)
    }
  ''';

  /// Get all children linked to a parent
  static Future<List<Map<String, dynamic>>> getParentChildren(
    String parentId,
    BuildContext context,
  ) async {
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

      final children = result.data?['parentChildren'] as List<dynamic>?;
      return children?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to get parent children: $e');
    }
  }

  /// Link a parent to a child by child ID
  static Future<bool> linkParentToChild(
    String parentId,
    String childId,
    BuildContext context,
  ) async {
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
      throw Exception('Failed to link parent to child: $e');
    }
  }

  /// Get child by username (for linking via username)
  static Future<Map<String, dynamic>?> getChildByUsername(
    String username,
    BuildContext context,
  ) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_getChildByUsernamQuery),
          variables: {
            'username': username,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['childByUsername'] as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get child by username: $e');
    }
  }

  /// Check if a parent is already linked to a specific child
  static Future<bool> isParentLinkedToChild(
    String parentId,
    String childId,
    BuildContext context,
  ) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.query(
        QueryOptions(
          document: gql(_isParentLinkedToChildQuery),
          variables: {
            'parentId': parentId,
            'childId': childId,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['isParentLinkedToChild'] ?? false;
    } catch (e) {
      throw Exception('Failed to check parent-child link: $e');
    }
  }
}

