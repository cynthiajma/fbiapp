import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:fluttermoji/fluttermojiFunctions.dart';
import 'package:get/get.dart';
import '../services/user_state_service.dart';
import '../services/child_data_service.dart';
import '../services/avatar_storage_service.dart';
import '../features/character.dart';
import '../widgets/char_row.dart';

class ChildProfilePage extends StatefulWidget {
  const ChildProfilePage({super.key});

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  String _childName = 'Loading...';
  List<Character> _characters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    try {
      // Get current child ID
      final childId = await UserStateService.getChildId();
      if (childId == null) {
        setState(() {
          _errorMessage = 'No child selected';
          _isLoading = false;
        });
        return;
      }

      // Load child profile and logs
      final childProfile = await ChildDataService.getChildProfile(childId, context);
      final childLogs = await ChildDataService.getChildLogs(childId, context);
      final characterLibrary = await ChildDataService.getCharacterLibrary(context);

      if (childProfile != null) {
        setState(() {
          _childName = childProfile['username'] ?? 'Unknown Child';
        });
      }

      // Process logs to create individual log entries
      final logEntries = ChildDataService.processLogsToIndividualEntries(childLogs, characterLibrary);
      
      // Convert to Character objects for display
      final characters = logEntries.map((entry) {
        final character = entry['character'] as Map<String, dynamic>;
        final characterName = entry['characterName'] as String;
        final level = entry['level'] as int;
        final progress = entry['progress'] as double;
        final date = entry['date'] as DateTime;
        
        return Character(
          name: characterName,
          imageAsset: 'data/characters/${ChildDataService.getCharacterImagePath(characterName)}',
          progress: progress,
          date: date,
          averageLevel: level,
        );
      }).toList();

      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _openCustomization() {
    Get.put(FluttermojiController());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _AvatarCustomizationPage(),
      ),
    ).then((_) {
      // Reload data after returning from customization
      setState(() {});
    });
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadChildData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          children: [
                            // Top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                    icon: const Icon(Icons.arrow_back, color: Color(0xff4a90e2), size: 24),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    tooltip: 'Back to Home',
                                  ),
                                ),
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
                                    icon: const Icon(Icons.edit, color: Color(0xffe67268), size: 24),
                                    onPressed: _openCustomization,
                                    tooltip: 'Customize Avatar',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Title
                            Transform.rotate(
                              angle: -2 * 3.1416 / 180,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8DC),
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
                                      top: 10,
                                      left: 10,
                                      child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                    ),
                                    Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: _openCustomization,
                                          child: FluttermojiCircleAvatar(radius: 50),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _childName.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'SpecialElite',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 32,
                                            color: Colors.black87,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffe67268),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified_user,
                                                  color: Colors.white, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'DETECTIVE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _PinnedStatsNote(
                                    number: _characters.length,
                                    label: 'Investigations',
                                    rotation: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _PinnedStatsNote(
                                    number: _calculateTotalStars(),
                                    label: 'Stars',
                                    rotation: -2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // My Characters Section
                            if (_characters.isNotEmpty) ...[
                              Transform.rotate(
                                angle: 1 * 3.1416 / 180,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
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
                                        top: 8,
                                        left: 10,
                                        child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'MY CHARACTERS',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            for (int i = 0; i < _characters.length; i++) ...[
                                              CharacterRow(c: _characters[i]),
                                              if (i != _characters.length - 1)
                                                const SizedBox(height: 12),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else
                              Transform.rotate(
                                angle: -0.5 * 3.1416 / 180,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
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
                                        top: 8,
                                        left: 10,
                                        child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Column(
                                          children: [
                                            Icon(Icons.emoji_emotions_outlined,
                                                size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Start your first investigation!',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                color: Colors.grey[700],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Log your feelings to see them here',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                color: Colors.grey[500],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  int _calculateTotalStars() {
    return _characters.fold(
      0,
      (sum, character) => sum + character.averageLevel,
    );
  }
}

class _PinnedStatsNote extends StatelessWidget {
  final int number;
  final String label;
  final double rotation;

  const _PinnedStatsNote({
    required this.number,
    required this.label,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1416 / 180,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E68C),
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
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  Text(
                    number.toString(),
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCustomizationPage extends StatelessWidget {
  const _AvatarCustomizationPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Avatar'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FluttermojiCircleAvatar(radius: 18),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview section
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.grey[50],
            child: Column(
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FluttermojiCircleAvatar(radius: 50),
                const SizedBox(height: 8),
                const Text(
                  'Tap to zoom',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Customizer
          Expanded(child: FluttermojiCustomizer()),
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () async {
                final controller = Get.find<FluttermojiController>();
                await controller.setFluttermoji();
                final childId = await UserStateService.getChildId();
                if (childId != null) {
                  // Get the options directly from the controller after saving
                  final avatarOptions = await FluttermojiFunctions().encodeMySVGtoString();
                  if (avatarOptions.isNotEmpty) {
                    await AvatarStorageService.saveAvatarOptions(
                      childId,
                      avatarOptions,
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xffe67268),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Save Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

