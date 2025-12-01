import 'package:flutter/material.dart';
import 'dart:convert';
import 'heartbeat_page.dart';
import 'butterfly.dart';
import 'sweat.dart';
import 'rock.dart';
import 'gerda.dart';
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
            MaterialPageRoute(builder: (_) => const HeartbeatPage(fromCharacterLibrary: true)),
          );
        };
      case 'Samantha Sweat':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SamanthaPage(fromCharacterLibrary: true)),
          );
        };
      case 'Betty Butterfly':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BettyPage(fromCharacterLibrary: true)),
          );
          
        };
        case 'Gerda Gotta Go':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GerdaPage(fromCharacterLibrary: true)),
          );
        };
      case 'Ricky the Rock':
        return () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RickyPage(fromCharacterLibrary: true)),
          );
        };
      default:
        return null;
    }
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
            child: _buildBody(),
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

    return Column(
      children: [
        // Top bar with back button and title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Back to Home',
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  'Character Library',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpecialElite',
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                    color: Colors.black87,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 3),
                        blurRadius: 2,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 56), // Spacer to balance the back button
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: characters.length + 12, // 3 extra rows of CLASSIFIED (4x3)
            itemBuilder: (context, index) {
              if (index < characters.length) {
                final character = characters[index];
                return _CharacterCard(
                  character: character,
                  onTap: _getNavigationCallback(character.name),
                  rotation: (index % 5 - 2) * 2.0, // Vary rotation between -4 and 4 degrees
                );
              }

              return _CharacterCard(
                character: null,
                label: 'CLASSIFIED',
                rotation: ((index - characters.length) % 5 - 2) * 2.0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character? character;
  final String? label;
  final VoidCallback? onTap;
  final double rotation;

  const _CharacterCard({
    this.character,
    this.label,
    this.onTap,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1416 / 180,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
              // Push pin icon
              const Positioned(
                top: 6,
                left: 10,
                child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
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
                      style: const TextStyle(
                        fontFamily: 'SpecialElite',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _RedStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw red strings across the canvas
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
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.65,
      size.width,
      size.height * 0.6,
    );
    canvas.drawPath(path2, paint);

    final path3 = Path();
    path3.moveTo(0, size.height * 0.85);
    path3.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.9,
      size.width,
      size.height * 0.85,
    );
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


