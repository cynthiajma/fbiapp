import 'package:flutter/material.dart';
import '../features/character.dart';
import '../widgets/char_row.dart';
import 'parent_child_selector_page.dart';
import 'home_page.dart';

class ParentProfilePage extends StatelessWidget {
  const ParentProfilePage({super.key});

  List<Character> _seed() => [
        Character(
          name: 'Henry Heartbeat',
          imageAsset: 'data/characters/henry_heartbeat.png',
          progress: 0.60,
          date: DateTime(2025, 10, 2),
        ),
        Character(
          name: 'Gerda Gotta Go',
          imageAsset: 'data/characters/gerda_gotta_go.png',
          progress: 0.35,
          date: DateTime(2025, 10, 3),
        ),
        Character(
          name: 'Samantha Sweat',
          imageAsset: 'data/characters/samatha_sweat.png',
          progress: 0.78,
          date: DateTime(2025, 10, 5),
        ),
        Character(
          name: 'Patricia the Poop Pain',
          imageAsset: 'data/characters/patricia_the_poop_pain.png',
          progress: 0.50,
          date: DateTime(2025, 11, 20),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final characters = _seed();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'JOHN SMITH',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Big user glyph
          Center(
            child: CircleAvatar(
              radius: 84,
              backgroundColor: Colors.black.withOpacity(0.06),
              child: const Icon(Icons.person, size: 96, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),

          // View My Children Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ParentChildSelectorPage(),
                  ),
                );
              },
              icon: const Icon(Icons.family_restroom),
              label: const Text('View My Children'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4a90e2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "JOHN'S CHARACTERS",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),

          // Rounded table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E4E2)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  color: Colors.black.withOpacity(0.04),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < characters.length; i++) ...[
                  CharacterRow(c: characters[i]),
                  if (i != characters.length - 1)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEDEBEA)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

