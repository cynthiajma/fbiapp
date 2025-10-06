import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'character_library.dart';
import 'pages/parent_profile.dart';
import 'heartbeat.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color pastelPink = const Color(0xFFFFE4EC);
    final Color titleBlue = const Color(0xFF5AA7FF);

    return Scaffold(
      backgroundColor: pastelPink,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: pastelPink,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParentProfilePage()),
            );
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _ProfileButton(),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Feelings and Body\nInvestigation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleBlue,
                    fontFamily: 'Scripto',
                    fontWeight: FontWeight.w600,
                    fontSize: 72,
                    letterSpacing: 0.8,
                    height: 1.1,
                    shadows: const [
                      Shadow(offset: Offset(0, 2), blurRadius: 0, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 64,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CharacterLibraryPage()),
                            );
                          },
                          child: const Text('Start'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.black26, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {},
                                child: const Text('Games'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.black26, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const HeartbeatPage()),
                                   );
                                },
                                child: const Text('Investigate'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
        // Ensures Fluttermoji controller is available and opens Avatar editor
        Get.put(FluttermojiController());
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _AvatarScaffold()),
        );
      },
      child: FluttermojiCircleAvatar(radius: 20),
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


