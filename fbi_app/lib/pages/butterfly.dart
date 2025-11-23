// lib/butterfly.dart

import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../services/logging_service.dart';
import '../services/user_state_service.dart';

class BettyPage extends StatefulWidget {
  const BettyPage({Key? key}) : super(key: key); 

  @override
  _BettyPageState createState() => _BettyPageState();
}

class _BettyPageState extends State<BettyPage>
    with SingleTickerProviderStateMixin {
  
  int _tapCounter = 5; 
  bool _isLogging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false;
  bool _isLoadingAudio = false;
  Uint8List? _audioBytes;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    _loadCharacterAudio();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCharacterAudio() async {
    setState(() {
      _isLoadingAudio = true;
    });

    try {
      // Load audio from local assets and store the bytes
      final ByteData data = await rootBundle.load('data/audio/betty-butterfly.mp3');
      _audioBytes = data.buffer.asUint8List();
      
      setState(() {
        _isLoadingAudio = false;
      });
    } catch (e) {
      print('Error loading character audio: $e');
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (_isLoadingAudio || _audioBytes == null) return;

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
        // For web (Chrome): Use AssetSource
        audioSource = AssetSource('data/audio/betty-butterfly.mp3');
      } else {
        // For native platforms (iOS/Android/macOS/Linux/Windows): Use temporary file
        // Create the temp file right before playing (like Henry does)
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/betty_butterfly.mp3');
        await tempFile.writeAsBytes(_audioBytes!);
        audioSource = DeviceFileSource(tempFile.path);
      }
      
      await _audioPlayer.play(audioSource);
      
      // Show "audio playing" snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playing...'),
            duration: Duration(seconds: 2), 
            backgroundColor: Colors.blue,
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
    if (_isLoadingAudio || _audioBytes == null) return;
    
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
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Corrected function to log the feeling with the proper String type for investigation.
  Future<void> _logFeeling(String stepName) async {
    if (_isLogging) return;

    setState(() {
      _isLogging = true;
    });

    try {
      final childId = await UserStateService.getChildId();
      if (childId != null) {
        // NOTE: Character ID for Betty is assumed to be '2'. Adjust if needed.
        // Inside _logFeeling function (around line 60)
      await LoggingService.logFeeling(
        childId: childId,
        characterId: '2', 
        level: _tapCounter,
        context: context,
        // FIX: Wrapping stepName in a List again (as originally required by your service)
        investigation: [stepName], 
      );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feeling logged successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging feeling: $e')),
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

  /// Builds a single, dynamically positioned butterfly (the animation fix).
  Widget _buildButterfly({
    required double baseLeft,
    required double baseTop,
    required double moveMagnitude,
    double timeOffset = 0.0,
    double size = 30.0,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.value;
        final time = (value + timeOffset) * 2 * pi;

        // Uses sine and cosine waves to create a natural, non-linear flutter path
        final dx = sin(time * 2) * moveMagnitude; 
        final dy = cos(time * 3) * moveMagnitude / 1.5; 

        return Positioned(
          left: baseLeft + dx,
          top: baseTop + dy,
          child: Opacity(
            opacity: 0.8,
            child: child!,
          ),
        );
      },
      child: Icon(
        Icons.flutter_dash, // Placeholder for your butterfly asset
        color: Colors.pink.shade300,
        size: size,
        shadows: [
          Shadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10.0,
            offset: const Offset(2, 2),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffcefee),
      appBar: AppBar(
        backgroundColor: const Color(0xfffcefee),
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        actions: [
          // Play/Pause button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.pink.shade400,
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
              onPressed: _isLoadingAudio ? null : _toggleAudio,
              tooltip: _isLoadingAudio 
                  ? 'Loading audio...' 
                  : (_isPlayingAudio ? 'Pause audio' : 'Play character voiceover'),
            ),
          ),
          // Replay button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.pink.shade400,
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
              onPressed: _isLoadingAudio ? null : _replayAudio,
              tooltip: _isLoadingAudio 
                  ? 'Loading audio...' 
                  : 'Replay audio from beginning',
            ),
          ),
        ],
      ),
      body: Container(
        // Colorful & Engaging UI: Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfffcefee), Color(0xfff7c4e0)], // Soft Pink/Purple
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // --- The "Flying Right" Butterflies ---
            _buildButterfly(
              baseLeft: 50, baseTop: 150, moveMagnitude: 20, timeOffset: 0.1, size: 28),
            _buildButterfly(
              baseLeft: 250, baseTop: 200, moveMagnitude: 30, timeOffset: 0.4, size: 35),
            _buildButterfly(
              baseLeft: 100, baseTop: 400, moveMagnitude: 25, timeOffset: 0.6, size: 32),
            _buildButterfly(
              baseLeft: 300, baseTop: 500, moveMagnitude: 20, timeOffset: 0.9, size: 25),

            // --- The Page Content (Centered) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Audio instruction text for mobile
                    if (!_isLoadingAudio)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              size: 18,
                              color: Colors.pink.shade400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tap the buttons above to listen to Betty!',
                              style: GoogleFonts.nunito(
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
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                      // Betty's main icon/image
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 15,
                            )
                          ]
                        ),
                        child: Icon(
                          Icons.flutter_dash, // Placeholder for Betty asset
                          size: 90,
                          color: Colors.pink.shade400,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- Single Sentence Intro ---
                      Text(
                        "Hi! I'm Betty the Butterfly! I cause a fluttering in your stomach when you feel anxious, worried, or maybe even excited about something.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Slider to set anxiety level
                      Text('My current flutter level: ${_tapCounter * 10}%',
                         style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                        value: _tapCounter.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (double value) {
                          setState(() {
                            _tapCounter = value.round();
                          });
                        },
                        activeColor: Colors.pinkAccent,
                        inactiveColor: Colors.pink.shade100,
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLogging ? null : () => _logFeeling('user_set_flutter_level'),
                          icon: _isLogging
                              ? const SizedBox(
                                  width: 20, height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_isLogging ? 'CALMING...' : 'Calm the Butterflies'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        ),
                      ),
                            ],
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
      ),
    );
  }
}