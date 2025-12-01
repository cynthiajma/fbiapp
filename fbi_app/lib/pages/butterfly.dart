// lib/butterfly.dart

import 'dart:async';
import 'dart:convert';
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
import 'gerda.dart';

class BettyPage extends StatefulWidget {
  final bool fromCharacterLibrary;
  
  const BettyPage({Key? key, this.fromCharacterLibrary = false}) : super(key: key); 

  @override
  _BettyPageState createState() => _BettyPageState();
}

class _BettyPageState extends State<BettyPage>
    with SingleTickerProviderStateMixin {
  
  // Now tracks the answer to the current question (Tap Score)
  int _tapCounter = 0; 
  static const int _maxTaps = 10; 
  bool _isLogging = false;
  bool _allQuestionsCompleted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false;
  bool _isLoadingAudio = false;
  Uint8List? _audioBytes;
  
  // State for the questions
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    "How many butterflies would fly out if you were on a swing?",
    "How many butterflies fly out when you are riding a rollercoaster?",
    "How many butterflies fly out when you are alone in a dark room?",
  ];

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
        // For web: Use data URL (base64) - AssetSource doesn't work on web
        final base64Audio = base64Encode(_audioBytes!);
        audioSource = UrlSource('data:audio/mp3;base64,$base64Audio');
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
    if (_isLoadingAudio || _audioBytes == null) return;
    await _audioPlayer.stop();
    setState(() { _isPlayingAudio = false; _hasPlayedOnce = false; });
    if (mounted) { 
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio reset to beginning'), duration: Duration(seconds: 1), backgroundColor: Colors.blue));
    }
  }
  
  // NEW: Function to handle the tap counter
  void _handleButterflyTap() {
    if (_tapCounter < _maxTaps) {
      setState(() {
        _tapCounter++;
      });
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Maximum count reached! Press 'Next Question' or 'Save'."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      }
    }
  }

  // NEW: Function to advance to the next question
  void _nextQuestion() {
    // Before moving to the next question, log the current tap score
    _logFeeling('Answered Question ${_currentQuestionIndex + 1}');
    
    // Check if there are more questions
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _tapCounter = 0; // Reset counter for the next question
      });
    } else {
      // If all questions are answered, just reset the counter
       setState(() {
        _allQuestionsCompleted = true;
        _currentQuestionIndex = 0; // Loop back to the first question
        _tapCounter = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You answered all the questions! Starting over."),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.pink,
          ),
        );
      }
    }
  }

  /// Corrected function to log the feeling with the proper List<String>? for investigation.
  Future<void> _logFeeling(String stepName) async {
    if (_isLogging) return;

    setState(() {
      _isLogging = true;
    });

    try {
      final childId = await UserStateService.getChildId();
      if (childId != null) {
        await LoggingService.logFeeling(
          childId: childId,
          characterId: '2', 
          level: _tapCounter, // Logs the tap count (answer)
          context: context,
          investigation: [stepName], 
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

  /// Builds a single, dynamically positioned butterfly (now using the correct asset).
  Widget _buildButterfly({
    required double baseLeft,
    required double baseTop,
    required double moveMagnitude,
    double timeOffset = 0.0,
    double size = 30.0,
    required String assetPath, // Pass the asset path here
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.value;
        final time = (value + timeOffset) * 2 * pi;

        // Uses sine and cosine waves for the flutter path
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
      // Now uses the actual Image.asset for the butterfly
      child: Image.asset(
        assetPath, 
        height: size,
        width: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the size of the main image based on the tap counter
    double scaleFactor = 1.0 + (_tapCounter / _maxTaps) * 0.15;
    // Path for Betty's asset
    const String bettyAsset = 'data/characters/betty_butterfly.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfffcefee),
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
          // Audio buttons remain the same
          // ... (Play/Pause and Replay buttons)
          Container( /* Play/Pause Button */
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration( color: Colors.pink.shade400, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2), ),],),
            child: IconButton(
              icon: Icon(_isPlayingAudio ? Icons.pause_rounded : (_hasPlayedOnce ? Icons.play_arrow_rounded : Icons.volume_up_rounded), color: Colors.white,),
              onPressed: _isLoadingAudio ? null : _toggleAudio,
              tooltip: _isLoadingAudio ? 'Loading audio...' : (_isPlayingAudio ? 'Pause audio' : 'Play character voiceover'),
            ),
          ),
          Container( /* Replay button */
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration( color: Colors.pink.shade400, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2), ),],),
            child: IconButton(
              icon: const Icon(Icons.replay_rounded, color: Colors.white,),
              onPressed: _isLoadingAudio ? null : _replayAudio,
              tooltip: _isLoadingAudio ? 'Loading audio...' : 'Replay audio from beginning',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfffcefee), Color(0xfff7c4e0)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // --- The "Flying Right" Butterflies (MORE OF THEM & using Betty Asset) ---
            _buildButterfly(assetPath: bettyAsset, baseLeft: 50, baseTop: 150, moveMagnitude: 20, timeOffset: 0.1, size: 28),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 250, baseTop: 200, moveMagnitude: 30, timeOffset: 0.4, size: 35),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 100, baseTop: 400, moveMagnitude: 25, timeOffset: 0.6, size: 32),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 300, baseTop: 500, moveMagnitude: 20, timeOffset: 0.9, size: 25),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 20, baseTop: 300, moveMagnitude: 15, timeOffset: 0.2, size: 20), // Added more
            _buildButterfly(assetPath: bettyAsset, baseLeft: 350, baseTop: 450, moveMagnitude: 40, timeOffset: 0.7, size: 38), // Added more
            _buildButterfly(assetPath: bettyAsset, baseLeft: 180, baseTop: 80, moveMagnitude: 22, timeOffset: 0.4, size: 30), // Added more
            _buildButterfly(assetPath: bettyAsset, baseLeft: 700, baseTop: 50, moveMagnitude: 10, timeOffset: 0.6, size: 40),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 680, baseTop: 450, moveMagnitude: 40, timeOffset: 0.2, size: 20),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 600, baseTop: 20, moveMagnitude: 25, timeOffset: 0.5, size: 25),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 750, baseTop: 120, moveMagnitude: 50, timeOffset: 0.01, size: 20),
            _buildButterfly(assetPath: bettyAsset, baseLeft: 900, baseTop: 150, moveMagnitude: 30, timeOffset: 0.8, size: 30),
            // --- The Page Content (Centered) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- TOP EXPLANATION TEXT ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.pinkAccent.shade100)
                      ),
                      child: Text(
                        "Hi! I'm Betty the Butterfly! I cause that fluttery feeling in your stomach when you get nervous. Help me count how many butterflies fly out for each situation.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- CURRENT QUESTION ---
                    Text(
                      _questions[_currentQuestionIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tap Counter Display
                    Text(
                      'Butterflies Flown Out: **$_tapCounter**',
                      style: GoogleFonts.nunito(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.pink.shade700),
                    ),
                    const SizedBox(height: 15),
                    
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: _handleButterflyTap, // Taps increment the counter
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 200 * scaleFactor,
                            height: 200 * scaleFactor,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 15 * scaleFactor,
                                )
                              ]
                            ),
                            // Main Tappable Betty Image
                            child: Image.asset(
                              bettyAsset, 
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- Action Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Save/Next Button
                        ElevatedButton.icon(
                          onPressed: _isLogging || _tapCounter == 0 ? null : _nextQuestion,
                          icon: _isLogging
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(_currentQuestionIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check_circle_outline),
                          label: Text(_currentQuestionIndex < _questions.length - 1 ? 'Next Question' : 'Save Final Answer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        
                        // Reset Button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _tapCounter = 0;
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Colors.grey),
                          label: Text('Reset', style: GoogleFonts.nunito(color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                    // --- NEXT CHARACTER BUTTON (only show after all questions completed) ---
                    if (_allQuestionsCompleted) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => GerdaPage(fromCharacterLibrary: widget.fromCharacterLibrary)),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('NEXT CHARACTER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
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