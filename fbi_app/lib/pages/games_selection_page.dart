import 'package:flutter/material.dart';
import 'memory_game_page.dart';

class GamesSelectionPage extends StatelessWidget {
  const GamesSelectionPage({super.key});

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Top bar with back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Choose Your Game',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpecialElite',
                      fontWeight: FontWeight.w700,
                      fontSize: 48,
                      color: Colors.black87,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 3),
                          blurRadius: 2,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),

                  // Game buttons
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: _PinnedNoteButton(
                              text: 'Character\nMatching',
                              color: const Color(0xFFFFF8DC),
                              rotation: -1,
                              width: 200,
                              height: 140,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MemoryGamePage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _RedStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw red strings
    final path1 = Path();
    path1.moveTo(0, size.height * 0.45);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      size.width,
      size.height * 0.47,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.7,
      size.width,
      size.height * 0.6,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

