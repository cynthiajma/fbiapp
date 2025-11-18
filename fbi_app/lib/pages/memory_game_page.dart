import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../services/character_service.dart';

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  List<GameCard> cards = [];
  List<int> flippedIndices = [];
  List<int> matchedPairs = [];
  bool isProcessing = false;
  bool isGameWon = false;
  int moves = 0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      final allCharacters = await CharacterService.getCharacters();
      
      if (allCharacters.length < 8) {
        setState(() {
          error = 'Not enough characters in library. Need at least 8 characters.';
          isLoading = false;
        });
        return;
      }

      // Take first 8 characters and create pairs
      final selectedCharacters = allCharacters.take(8).toList();
      final List<GameCard> gameCards = [];

      // Pre-decode all images and create pairs
      for (var character in selectedCharacters) {
        Uint8List? imageBytes;
        if (character.photo != null) {
          try {
            imageBytes = base64Decode(character.photo!);
          } catch (e) {
            // If decoding fails, imageBytes stays null
          }
        }
        
        // Create two cards with the same character and pre-decoded image
        gameCards.add(GameCard(
          character: character,
          id: character.id,
          imageBytes: imageBytes,
        ));
        gameCards.add(GameCard(
          character: character,
          id: character.id,
          imageBytes: imageBytes,
        ));
      }

      // Shuffle the cards
      gameCards.shuffle(Random());

      setState(() {
        cards = gameCards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load characters: $e';
        isLoading = false;
      });
    }
  }

  void _handleCardTap(int index) {
    if (isProcessing || 
        flippedIndices.contains(index) || 
        matchedPairs.contains(index) ||
        flippedIndices.length >= 2) {
      return;
    }

    setState(() {
      flippedIndices.add(index);
    });

    if (flippedIndices.length == 2) {
      setState(() {
        moves++;
        isProcessing = true;
      });

      // Check if cards match
      final firstIndex = flippedIndices[0];
      final secondIndex = flippedIndices[1];

      if (cards[firstIndex].id == cards[secondIndex].id) {
        // Match found!
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            matchedPairs.add(firstIndex);
            matchedPairs.add(secondIndex);
            flippedIndices.clear();
            isProcessing = false;

            // Check if game is won
            if (matchedPairs.length == 16) {
              isGameWon = true;
            }
          });
        });
      } else {
        // No match - flip cards back
        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            flippedIndices.clear();
            isProcessing = false;
          });
        });
      }
    }
  }

  void _resetGame() {
    setState(() {
      flippedIndices.clear();
      matchedPairs.clear();
      isProcessing = false;
      isGameWon = false;
      moves = 0;
    });
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'New Game',
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetGame,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (isGameWon) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You matched all pairs in $moves moves!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Score/Moves display
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Moves', moves.toString()),
              _buildStatCard('Pairs Found', '${matchedPairs.length ~/ 2}/8'),
            ],
          ),
        ),
        // Game grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return _MemoryCard(
                  card: cards[index],
                  isFlipped: flippedIndices.contains(index) || matchedPairs.contains(index),
                  onTap: () => _handleCardTap(index),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class GameCard {
  final Character character;
  final String id;
  final Uint8List? imageBytes; // Pre-decoded image bytes

  GameCard({
    required this.character,
    required this.id,
    this.imageBytes,
  });
}

class _MemoryCard extends StatelessWidget {
  final GameCard card;
  final bool isFlipped;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isFlipped ? _buildFlippedCard() : _buildBackCard(),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      color: const Color(0xFF4A90E2),
      child: const Center(
        child: Icon(
          Icons.help_outline,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFlippedCard() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCharacterImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              card.character.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage() {
    if (card.imageBytes != null) {
      return Image.memory(
        card.imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}

