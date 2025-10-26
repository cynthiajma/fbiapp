import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'character_library.dart';
import 'pages/parent_login_page.dart';
import 'heartbeat.dart';
import 'services/user_state_service.dart';

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_pin, color: Colors.brown),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ParentLoginPage()),
                          );
                        },
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PinnedNoteButton(
                          text: 'Start Case',
                          color: const Color(0xFFFFF8DC),
                          rotation: -1,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CharacterLibraryPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _PinnedNoteButton(
                                text: 'Games',
                                color: const Color(0xFFFAF0E6),
                                rotation: 2.5,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PinnedNoteButton(
                                text: 'Investigate',
                                color: const Color(0xFFF0E68C),
                                rotation: -3.5,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const HeartbeatPage()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer pinned note
                  Transform.rotate(
                    angle: 0.015,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            offset: Offset(1, 2),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: Text(
                        '$_detectiveName 🕵️‍♀️',
                        style: const TextStyle(
                          fontFamily: 'SpecialElite',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
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

  const _PinnedNoteButton({
    required this.text,
    required this.color,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1416 / 180,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
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
    return GestureDetector(
      onTap: () {
        Get.put(FluttermojiController());
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _AvatarScaffold()),
        );
      },
      child: FluttermojiCircleAvatar(radius: 22),
    );
  }
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
