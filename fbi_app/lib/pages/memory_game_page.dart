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
      body: Stack(
        children: [
          // Corkboard background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/corkboard.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Optional semi-transparent overlay
          Container(color: Colors.brown.withOpacity(0.1)),

          // Red strings connecting elements
          CustomPaint(
            painter: _RedStringPainter(),
            child: Container(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar with back button and refresh
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                      const Text(
                        'Character Matching',
                        style: TextStyle(
                          fontFamily: 'SpecialElite',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black87),
                        onPressed: _resetGame,
                        tooltip: 'New Game',
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -2 * 3.1416 / 180,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DC),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(3, 3),
                          blurRadius: 5,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 6,
                          left: 10,
                          child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.celebration, size: 80, color: Colors.amber),
                            const SizedBox(height: 16),
                            const Text(
                              'Case Solved!',
                              style: TextStyle(
                                fontFamily: 'SpecialElite',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You matched all pairs in $moves moves!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'SpecialElite',
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _PinnedNoteButton(
                  text: 'Play Again',
                  color: const Color(0xFFFFF8DC),
                  rotation: 1.5,
                  width: 180,
                  height: 60,
                  onTap: _resetGame,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        // Score/Moves display - styled as pinned notes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Moves', moves.toString()),
              _buildStatCard('Pairs Found', '${matchedPairs.length ~/ 2}/8'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Game grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Transform.rotate(
      angle: (Random().nextDouble() * 4 - 2) * 3.1416 / 180, // Random rotation between -2 and 2 degrees
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8DC),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.black26,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.push_pin, color: Colors.redAccent, size: 16),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedNoteButton extends StatelessWidget {
  final String text;
  final Color color;
  final double rotation;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const _PinnedNoteButton({
    required this.text,
    required this.color,
    required this.rotation,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1416 / 180,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? 64,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                offset: Offset(3, 3),
                blurRadius: 5,
                color: Colors.black26,
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 6,
                left: 10,
                child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
              ),
              Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              offset: Offset(3, 3),
              blurRadius: 5,
              color: Colors.black26,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: isFlipped ? _buildFlippedCard() : _buildBackCard(),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 6,
            left: 10,
            child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
          ),
          const Center(
            child: Icon(
              Icons.help_outline,
              size: 30,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlippedCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 6,
            left: 10,
            child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: _buildCharacterImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              card.character.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
            ],
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
        size: 30,
        color: Colors.grey,
      ),
    );
  }
}

class _RedStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw red strings
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width,
      size.height * 0.32,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width,
      size.height * 0.65,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

