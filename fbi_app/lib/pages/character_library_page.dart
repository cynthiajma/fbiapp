import 'package:flutter/material.dart';
import 'dart:convert';
import 'heartbeat_page.dart';
import 'butterfly.dart';
import 'sweat.dart';
import '../services/character_service.dart';


class CharacterLibraryPage extends StatefulWidget {
  const CharacterLibraryPage({super.key});

  @override
  State<CharacterLibraryPage> createState() => _CharacterLibraryPageState();
}

class _CharacterLibraryPageState extends State<CharacterLibraryPage> {
  List<Character> characters = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    try {
      final fetchedCharacters = await CharacterService.getCharacters();
      setState(() {
        characters = fetchedCharacters;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  VoidCallback? _getNavigationCallback(String? characterName) {
    if (characterName == null) return null;
    
    switch (characterName) {
      case 'Henry the Heartbeat':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeartbeatPage()),
          );
        };
      case 'Samantha Sweat':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SamanthaPage()),
          );
        };
      case 'Betty Butterfly':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BettyPage()),
          );
        };
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Library'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading characters',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                _loadCharacters();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: characters.length + 9, // 3 extra rows of CLASSIFIED (3x3)
      itemBuilder: (context, index) {
        if (index < characters.length) {
          final character = characters[index];
          return _CharacterCard(
            character: character,
            onTap: _getNavigationCallback(character.name),
          );
        }

        return const _CharacterCard(
          character: null,
          label: 'CLASSIFIED',
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character? character;
  final String? label;
  final VoidCallback? onTap;

  const _CharacterCard({
    this.character,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.grey.shade200,
                child: _buildImage(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            character?.name ?? label ?? 'Unknown',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (character?.photo != null) {
      // Display image from database (base64)
      try {
        final bytes = base64Decode(character!.photo!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage();
          },
        );
      } catch (e) {
        return _buildFallbackImage();
      }
    } else if (label == 'CLASSIFIED') {
      // Display classified image from assets
      return Image.asset(
        'data/characters/classified.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.broken_image,
        color: Colors.grey.shade600,
        size: 48,
      ),
    );
  }
}


