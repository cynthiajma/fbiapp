import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/logging_service.dart';
import '../services/user_state_service.dart';
import '../services/character_service.dart';
import 'home_page.dart';

class HeartbeatPage extends StatefulWidget {
  final bool fromCharacterLibrary;
  
  const HeartbeatPage({super.key, this.fromCharacterLibrary = false});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage>
    with SingleTickerProviderStateMixin {
  double _heartbeatSpeed = 0.5;
  late AnimationController _controller;
  bool _isLogging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _characterAudio;
  bool _isLoadingAudio = false;
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false;
  String? _characterId;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
    _loadCharacterAudio();
    _loadCharacterId();
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCharacterAudio() async {
    setState(() {
      _isLoadingAudio = true;
    });

    try {
      // Fetch characters from backend
      final characters = await CharacterService.getCharacters();
      
      // Find Henry the Heartbeat (character ID = 1)
      final henry = characters.firstWhere(
        (char) => char.id == '1',
        orElse: () => characters.first,
      );

      setState(() {
        _characterAudio = henry.audio;
        _isLoadingAudio = false;
      });
    } catch (e) {
      print('Error loading character audio: $e');
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _loadCharacterId() async {
    try {
      final characters = await CharacterService.getCharacters();
      final henry = characters.firstWhere(
        (char) => char.name == 'Henry the Heartbeat',
        orElse: () => characters.first,
      );
      setState(() {
        _characterId = henry.id;
      });
    } catch (e) {
      print('Error loading character ID: $e');
    }
  }

  Future<void> _toggleAudio() async {
    if (_characterAudio == null) return;

    // If already playing, pause it
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingAudio = false;
      });
      // Clear the snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio paused'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Otherwise, play or resume
    setState(() {
      _isPlayingAudio = true;
      _hasPlayedOnce = true;
    });

    try {
      Source audioSource;
      
      // Use different approach for web vs native platforms
      if (kIsWeb) {
        // For web (Chrome): Use data URL (base64)
        // _characterAudio is already base64 encoded from the backend
        audioSource = UrlSource('data:audio/mp3;base64,${_characterAudio!}');
      } else {
        // For native platforms (iOS/Android/macOS/Linux/Windows): Use temporary file
        // macOS doesn't support data URLs, so we need to use a file
        final audioBytes = base64Decode(_characterAudio!);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_audio.mp3');
        await tempFile.writeAsBytes(audioBytes);
        audioSource = DeviceFileSource(tempFile.path);
      }
      
      await _audioPlayer.play(audioSource);
      
      // Show "audio playing" snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playing...'),
            duration: Duration(seconds: 2), 
            backgroundColor: const Color(0xff4a90e2),
          ),
        );
      }
      
      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlayingAudio = false;
          _hasPlayedOnce = false; // Reset so speaker icon shows again
        });
        // Clear the snackbar when audio completes
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
      });
      
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  Future<void> _replayAudio() async {
    if (_characterAudio == null) return;

    // Stop current playback and reset to initial state
    await _audioPlayer.stop();
    
    setState(() {
      _isPlayingAudio = false;
      _hasPlayedOnce = false;
    });
    
    // Clear any existing snackbars
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio reset to beginning'),
          duration: Duration(seconds: 1),
          backgroundColor: const Color(0xff4a90e2),
        ),
      );
    }
  }

  void _updateSpeed(double value) {
    setState(() {
      _heartbeatSpeed = value;
      final newDuration =
          Duration(milliseconds: (1500 - (value * 1000)).toInt());
      _controller.duration = newDuration;
      _controller.repeat(reverse: true);
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.celebration, color: const Color(0xffe67268), size: 32),
              const SizedBox(width: 10),
              const Text('Great Job! ❤️'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'data/characters/heart.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              Text(
                'You completed the question with Henry Heartbeat!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'You learned to notice how fast your heart is beating. Keep listening to Henry!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to library
              },
              child: const Text('Back to Library', style: TextStyle(color: Color(0xffe67268))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logFeeling() async {
    if (_isLogging) return;

    setState(() {
      _isLogging = true;
    });

    try {
      // Convert slider value (0-1) to level (0-10)
      final level = (_heartbeatSpeed * 10).round();
      
      // Get childId from user state
      final childId = await UserStateService.getChildId();
      if (childId == null) {
        throw Exception('No child ID found. Please log in first.');
      }
      
      if (_characterId == null) {
        throw Exception('Character ID not loaded. Please try again.');
      }
      
      await LoggingService.logFeeling(
        childId: childId,
        characterId: _characterId!,
        level: level,
        context: context,
        investigation: ['How fast is your heartbeat right now? - Level: $level'],
      );

      if (mounted) {
        if (!widget.fromCharacterLibrary) {
          // Investigation mode: complete the investigation and go back to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Investigation complete! Great job detective! 🕵️'),
              backgroundColor: Color(0xff4a90e2),
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back to home page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else {
          // Library mode: show completion dialog
          _showCompletionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging feeling: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2f0f7),
      appBar: AppBar(
        backgroundColor: const Color(0xffd2f0f7),
        elevation: 0,
        leading: widget.fromCharacterLibrary
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null, // Default back button behavior
        actions: [
          // Play/Pause button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xffe67268),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlayingAudio 
                    ? Icons.pause_rounded 
                    : (_hasPlayedOnce ? Icons.play_arrow_rounded : Icons.volume_up_rounded),
                color: Colors.white,
              ),
              onPressed: _characterAudio == null || _isLoadingAudio
                  ? null
                  : _toggleAudio,
              tooltip: _isLoadingAudio 
                  ? 'Loading audio...' 
                  : (_characterAudio == null 
                      ? 'No audio available' 
                      : (_isPlayingAudio ? 'Pause audio' : 'Play character voiceover')),
            ),
          ),
          // Replay button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xffe67268),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.replay_rounded,
                color: Colors.white,
              ),
              onPressed: _characterAudio == null || _isLoadingAudio
                  ? null
                  : _replayAudio,
              tooltip: _isLoadingAudio 
                  ? 'Loading audio...' 
                  : (_characterAudio == null 
                      ? 'No audio available' 
                      : 'Replay audio from beginning'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Audio instruction text for mobile
              if (!_isLoadingAudio && _characterAudio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 18,
                        color: const Color(0xffe67268),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Tap the buttons above to listen to Henry!',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 16),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xffe67268),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HOW FAST IS YOUR\nHENRY HEARTBEAT GOING?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: AnimatedScale(
                    scale: _controller.value,
                    duration: const Duration(milliseconds: 100),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'data/characters/heart.png',
                          height: 200,
                        ),
                        Positioned(
                          top: 40,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Thinking...',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.emoji_nature_rounded, color: Color(0xFF4A90E2)),
                      SizedBox(width: 5),
                      Text('SLOW LIKE A TURTLE'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('FAST LIKE A RABBIT'),
                      SizedBox(width: 5),
                      Icon(Icons.pets_rounded, color: Color(0xFF9B59B6)),
                    ],
                  ),
                ],
              ),
              Slider(
                value: _heartbeatSpeed,
                onChanged: _updateSpeed,
                min: 0,
                max: 1,
                divisions: 5,
                activeColor: const Color(0xFF4A90E2),
                inactiveColor: const Color(0xFFB0D4F1),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xffe67268),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'You will feel Henry Heartbeat on the left side of your chest.\n\n'
                  'He will speed up the more you move, and slow down as you relax.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLogging ? null : _logFeeling,
                icon: _isLogging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLogging ? 'Saving...' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLogging
                      ? Colors.grey
                      : const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

