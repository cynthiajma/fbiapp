import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../features/character.dart';
import '../widgets/char_row.dart';
import '../services/user_state_service.dart';
import '../services/child_data_service.dart';
import '../home.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
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
          averageLevel: level, // This is now the individual level, not average
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
                      child: RefreshIndicator(
                        onRefresh: _loadChildData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              // Top bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.brown),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    tooltip: 'Back',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.brown),
                                    onPressed: _loadChildData,
                                    tooltip: 'Refresh',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Title
                              Transform.rotate(
                                angle: -1.5 * 3.1416 / 180,
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
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 50,
                                              backgroundColor: Colors.brown.withOpacity(0.1),
                                              child: const Icon(Icons.person, size: 60, color: Colors.brown),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "${_childName.toUpperCase()}'S PROFILE",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontFamily: 'SpecialElite',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 24,
                                                color: Colors.black87,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Character list
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
                                        child: _characters.isEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.all(24.0),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.emoji_emotions_outlined,
                                                        size: 48, color: Colors.grey[400]),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No character data available yet.',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'SpecialElite',
                                                        color: Colors.grey[700],
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Start logging feelings to see progress!',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'SpecialElite',
                                                        color: Colors.grey[500],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CHARACTERS",
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
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}