import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'character_library_page.dart';
import 'child_login_page.dart';
import 'child_profile_page.dart';
import 'heartbeat_page.dart';
import 'login_selection_page.dart';
import 'games_selection_page.dart';
import '../services/user_state_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _detectiveName = 'Detective NameHolder';

  @override
  void initState() {
    super.initState();
    _loadDetectiveName();
  }

  Future<void> _loadDetectiveName() async {
    final name = await UserStateService.getChildName();
    if (name != null) {
      setState(() {
        _detectiveName = name;
      });
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[400],
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
                          icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                          onPressed: () async {
                            await UserStateService.clearUserData();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginSelectionPage()),
                                (route) => false,
                              );
                            }
                          },
                          tooltip: 'Logout',
                        ),
                      ),
                      const _ProfileButton(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    'Feelings and Body\nInvestigation',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontWeight: FontWeight.w700,
                      fontSize: 56,
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

                  const SizedBox(height: 40),

                  // Pinned notes/buttons
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: _PinnedNoteButton(
                              text: 'Start Case',
                              color: const Color(0xFFFFF8DC),
                              rotation: -1,
                              width: 140,
                              height: 140,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CharacterLibraryPage()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PinnedNoteButton(
                                text: 'Games',
                                color: const Color(0xFFFFF8DC),
                                rotation: 2.5,
                                width: 140,
                                height: 140,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const GamesSelectionPage()),
                                  );
                                },
                              ),
                              const SizedBox(width: 28),
                              _PinnedNoteButton(
                                text: 'Investigate',
                                color: const Color(0xFFFFF8DC),
                                rotation: -3.5,
                                width: 140,
                                height: 140,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const HeartbeatPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
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

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 1.5 * 3.1416 / 180,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ChildProfilePage(),
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // When pushing: child profile slides in from right (1.0 -> 0.0)
                // When popping: animation reverses, so child profile slides out to right (0.0 -> 1.0)
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(1.0, 0.0), // Start from right
                    end: Offset.zero, // End at center
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
            ),
          );
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                offset: const Offset(3, 4),
                blurRadius: 6,
                color: Colors.black.withOpacity(0.32),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 6,
                left: 10,
                child: Icon(Icons.push_pin, color: Colors.redAccent, size: 16),
              ),
              Center(
                child: FluttermojiCircleAvatar(radius: 28),
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

    // Draw fewer, longer red strings spanning the entire width
    // First string passes through the top of the Start Case button (centered)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.45);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45, // Pass through center at top of Start Case button
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

class _AvatarScaffold extends StatelessWidget {
  const _AvatarScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FluttermojiCircleAvatar(radius: 18),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: FluttermojiCustomizer()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FluttermojiSaveWidget(),
          ),
        ],
      ),
    );
  }
}

