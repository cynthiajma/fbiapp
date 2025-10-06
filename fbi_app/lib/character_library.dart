import 'package:flutter/material.dart';
import 'heartbeat.dart';


class CharacterLibraryPage extends StatelessWidget {
  const CharacterLibraryPage({super.key});

  static const List<Map<String, String>> characters = [
    {"name": "Betty Butterfly", "asset": "data/characters/betty_butterfly.png"},
    {"name": "Gassy Gus", "asset": "data/characters/gassy_gus.png"},
    {"name": "Gerda Gotta Go", "asset": "data/characters/gerda_gotta_go.png"},
    {"name": "Gordon Gotta Go", "asset": "data/characters/gordon_gotta_go.png"},
    {"name": "Henry Heartbeat", "asset": "data/characters/henry_heartbeat.png"},
    {"name": "Patricia the Poop Pain", "asset": "data/characters/patricia_the_poop_pain.png"},
    {"name": "Polly Pain", "asset": "data/characters/polly_pain.png"},
    {"name": "Ricky the Rock", "asset": "data/characters/ricky_the_rock.png"},
    {"name": "Samatha Sweat", "asset": "data/characters/samatha_sweat.png"},
  ];

  static const String classifiedAsset = "data/characters/classified.png";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Library'),
      ),
      body: GridView.builder(
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
              imageAsset: character["asset"]!,
              label: character["name"]!,
              onTap: character["name"] == 'Henry Heartbeat'
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HeartbeatPage()),
                      );
                    }
                  : null,
            );
          }

          return const _CharacterCard(
            imageAsset: classifiedAsset,
            label: 'CLASSIFIED',
          );
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final VoidCallback? onTap;

  const _CharacterCard({required this.imageAsset, required this.label, this.onTap});

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
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.broken_image, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
    );
  }
}


