import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

class CharacterService {
  static const String _graphqlEndpoint = 'http://localhost:3000/graphql';
  
  static GraphQLClient get _client {
    final HttpLink httpLink = HttpLink(_graphqlEndpoint);
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  static const String getCharactersQuery = '''
    query GetCharacters {
      characterLibrary {
        id
        name
        photo
        description
      }
    }
  ''';

  static Future<List<Character>> getCharacters() async {
    try {
      final QueryResult result = await _client.query(
        QueryOptions(
          document: gql(getCharactersQuery),
        ),
      );

      if (result.hasException) {
        throw Exception('GraphQL Error: ${result.exception}');
      }

      final List<dynamic> charactersData = result.data?['characterLibrary'] ?? [];
      
      return charactersData.map((char) => Character.fromJson(char)).toList();
    } catch (e) {
      throw Exception('Failed to fetch characters: $e');
    }
  }
}

class Character {
  final String id;
  final String name;
  final String? photo; // Base64 encoded image
  final String? description;

  Character({
    required this.id,
    required this.name,
    this.photo,
    this.description,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      photo: json['photo'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'description': description,
    };
  }
}
