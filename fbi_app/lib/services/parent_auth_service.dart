import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

class ParentAuthService {
  static const String _createParentMutation = '''
    mutation CreateParent(\$username: String!, \$email: String!, \$password: String!, \$childId: ID) {
      createParent(username: \$username, email: \$email, password: \$password, childId: \$childId) {
        id
        username
        email
      }
    }
  ''';
  static const String _loginParentMutation = '''
    mutation LoginParent(\$username: String!, \$password: String!) {
      loginParent(username: \$username, password: \$password) {
        id
        username
        email
      }
    }
  ''';
  
  static const String _requestPasswordResetMutation = '''
    mutation RequestPasswordReset(\$email: String!) {
      requestPasswordReset(email: \$email)
    }
  ''';
  
  static const String _resetPasswordMutation = '''
    mutation ResetPassword(\$token: String!, \$newPassword: String!) {
      resetPassword(token: \$token, newPassword: \$newPassword)
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
        // Extract the clean error message from GraphQL response
        String errorMessage = 'Login failed';
        if (result.exception != null) {
          final errorString = result.exception.toString();
          
          // Try to extract from GraphQLError format
          // GraphQLError(message: "...", ...)
          final graphqlMatch = RegExp(r'message:\s*"([^"]+)"').firstMatch(errorString);
          if (graphqlMatch != null) {
            errorMessage = graphqlMatch.group(1)!;
          } else {
            // Try to extract message: ... 
            final messageMatch = RegExp(r'message:\s*([^\n,]+)').firstMatch(errorString);
            if (messageMatch != null) {
              // Remove quotes and other unwanted chars
              errorMessage = messageMatch.group(1)!.trim()
                .replaceAll('"', '')
                .replaceAll("'", '')
                .replaceAll(r'$', '');
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
        throw Exception(errorMessage);
      }

      return result.data?['loginParent'];
    } catch (e) {
      // Extract clean message from exception
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
      if (errorMsg.startsWith('Login failed: ')) {
        errorMsg = errorMsg.substring('Login failed: '.length);
      }
      throw Exception(errorMsg);
    }
  }

  /// Create a new parent and optionally link to a childId
  static Future<Map<String, dynamic>?> createParent({
    required String username,
    required String email,
    required String password,
    String? childId,
    required BuildContext context,
  }) async {
    try {
      final client = GraphQLProvider.of(context).value;

      final result = await client.mutate(
        MutationOptions(
          document: gql(_createParentMutation),
          variables: {
            'username': username,
            'email': email,
            'password': password,
            'childId': childId,
          },
        ),
      );

      if (result.hasException) {
        String errorMessage = 'Create parent failed';
        if (result.exception != null) {
          final errorString = result.exception.toString();
          final graphqlMatch = RegExp(r'message:\s*"([^"]+)"').firstMatch(errorString);
          if (graphqlMatch != null) {
            errorMessage = graphqlMatch.group(1)!;
          } else {
            errorMessage = errorString
                .replaceAll(RegExp(r'^(Exception|Error|GraphQLError|LinkException):\s*'), '')
                .split('\n')
                .first
                .trim();
          }
        }
        throw Exception(errorMessage);
      }

      return result.data?['createParent'];
    } catch (e) {
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
      throw Exception(errorMsg);
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

  /// Request password reset email
  static Future<bool> requestPasswordReset(String email, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.mutate(
        MutationOptions(
          document: gql(_requestPasswordResetMutation),
          variables: {
            'email': email,
          },
        ),
      );

      if (result.hasException) {
        // Extract clean error message
        String errorMessage = 'No account found with this email address';
        if (result.exception != null) {
          final errorString = result.exception.toString();
          final graphqlMatch = RegExp(r'message:\s*"([^"]+)"').firstMatch(errorString);
          if (graphqlMatch != null) {
            errorMessage = graphqlMatch.group(1)!;
          } else {
            errorMessage = errorString
                .replaceAll(RegExp(r'^(Exception|Error|GraphQLError|LinkException):\s*'), '')
                .split('\n')
                .first
                .trim();
          }
        }
        throw Exception(errorMessage);
      }

      return result.data?['requestPasswordReset'] ?? false;
    } catch (e) {
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
      errorMsg = errorMsg.replaceFirst('Failed to request password reset: ', '');
      throw Exception(errorMsg);
    }
  }

  /// Reset password with token
  static Future<bool> resetPassword(String token, String newPassword, BuildContext context) async {
    try {
      final client = GraphQLProvider.of(context).value;
      
      final result = await client.mutate(
        MutationOptions(
          document: gql(_resetPasswordMutation),
          variables: {
            'token': token,
            'newPassword': newPassword,
          },
        ),
      );

      if (result.hasException) {
        String errorMessage = 'Password reset failed';
        if (result.exception != null) {
          final errorString = result.exception.toString();
          final graphqlMatch = RegExp(r'message:\s*"([^"]+)"').firstMatch(errorString);
          if (graphqlMatch != null) {
            errorMessage = graphqlMatch.group(1)!;
          }
        }
        throw Exception(errorMessage);
      }

      return result.data?['resetPassword'] ?? false;
    } catch (e) {
      String errorMsg = e.toString();
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
      throw Exception(errorMsg);
    }
  }
}
