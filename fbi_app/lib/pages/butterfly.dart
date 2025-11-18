// lib/butterfly.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

import '../services/logging_service.dart';
import '../services/user_state_service.dart';
import 'character_constants.dart'; // Using the constants file

class BettyPage extends StatefulWidget {
  const BettyPage({Key? key}) : super(key: key); 

  @override
  _BettyPageState createState() => _BettyPageState();
}

class _BettyPageState extends State<BettyPage>
    with SingleTickerProviderStateMixin {
  
  int _tapCounter = 5; 
  bool _isLogging = false;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
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
                        "Hi! I'm Betty, and those flutters are just my friends telling you they need a little calm.",
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
    );
  }
}