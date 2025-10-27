import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/user_state_service.dart';
import '../services/child_data_service.dart';
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
          _childName = childProfile['name'] ?? 'Unknown Child';
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
      body: _isLoading
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      // App Bar-like header
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Title
                            Text(
                              'MY PROFILE',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                            ),
                            // Edit button
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _openCustomization,
                              tooltip: 'Customize Avatar',
                            ),
                          ],
                        ),
                      ),

                      // Avatar Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xffe67268).withOpacity(0.1),
                              const Color(0xffe67268).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xffe67268).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Large Avatar
                            GestureDetector(
                              onTap: _openCustomization,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xffe67268),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[100],
                                    ),
                                    child: FluttermojiCircleAvatar(radius: 60),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Child Name
                            Text(
                              _childName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Detective badge
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
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'DETECTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Customize button
                            ElevatedButton.icon(
                              onPressed: _openCustomization,
                              icon: const Icon(Icons.palette, size: 20),
                              label: const Text('Customize Avatar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xffe67268),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.psychology,
                              number: _characters.length,
                              label: 'Feelings Investigated',
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: Colors.grey[300],
                            ),
                            _StatItem(
                              icon: Icons.star,
                              number: _calculateTotalStars(),
                              label: 'Stars Earned',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // My Characters Section
                      if (_characters.isNotEmpty) ...[
                        Text(
                          'MY CHARACTERS',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
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
                              for (int i = 0; i < _characters.length; i++) ...[
                                CharacterRow(c: _characters[i]),
                                if (i != _characters.length - 1)
                                  const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFEDEBEA)),
                              ],
                            ],
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E4E2)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_emotions_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Start your first investigation!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Log your feelings to see them here',
                                style: TextStyle(
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
    );
  }

  int _calculateTotalStars() {
    return _characters.fold(
      0,
      (sum, character) => sum + character.averageLevel,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int number;
  final String label;

  const _StatItem({
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xffe67268)),
        const SizedBox(height: 8),
        Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              onTap: () {
                // Save the avatar
                final controller = Get.find<FluttermojiController>();
                controller.setFluttermoji();
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

