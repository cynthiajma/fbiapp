// lib/pages/ricky_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

import '../services/logging_service.dart';
import '../services/user_state_service.dart';
import 'heartbeat_page.dart';

// Mock Constants (Delete if using separate file)
class CharacterConstants {
  static const String rickyTheRock = 'Ricky the Rock';
}

class RickyPage extends StatefulWidget {
  final bool fromCharacterLibrary;
  
  const RickyPage({Key? key, this.fromCharacterLibrary = false}) : super(key: key); 

  @override
  _RickyPageState createState() => _RickyPageState();
}

class _RickyPageState extends State<RickyPage> {
  
  // Tracks the "weight"/size of the rock (0.0 to 10.0)
  double _rockWeight = 0.0; 
  static const double _maxWeight = 10.0; 
  bool _isLogging = false;
  bool _allQuestionsCompleted = false;
  
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    "How heavy does the rock feel when you **hide a broken toy**?",
    "How heavy does the rock feel when you **say something mean** by accident?",
    "How heavy does the rock feel when you **don't tell the truth**?",
  ];

  // ----------------------------------------------------
  // HELPER: Descriptive Status
  // ----------------------------------------------------
  String _getWeightStatus(double weight) {
    if (weight < 1.0) return "🪶 LIGHT AS A FEATHER";
    if (weight < 3.0) return "🪨 TINY PEBBLE";
    if (weight < 6.0) return "🗿 HEAVY STONE";
    if (weight < 8.0) return "⛰️ GIANT BOULDER";
    return "🌋 CRUSHING WEIGHT!"; 
  }

  // ----------------------------------------------------
  // INTERACTION LOGIC: Vertical Drag
  // ----------------------------------------------------

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isLogging) return;

    // Sensitivity: How many pixels of drag equals 1 unit of weight
    const double sensitivity = 20.0; 

    setState(() {
      // Dragging DOWN (positive dy) increases weight
      // Dragging UP (negative dy) decreases weight
      double delta = details.delta.dy / sensitivity;
      
      _rockWeight += delta;
      
      // Clamp values between 0 and 10
      if (_rockWeight > _maxWeight) _rockWeight = _maxWeight;
      if (_rockWeight < 0.0) _rockWeight = 0.0;
    });
  }

  void _nextQuestion() {
    _logFeeling('Q${_currentQuestionIndex + 1}: ${_questions[_currentQuestionIndex]} - Weight: ${_rockWeight.toStringAsFixed(1)}');
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _rockWeight = 0.0; // Reset
        _allQuestionsCompleted = false;
      });
    } else {
      setState(() {
        _allQuestionsCompleted = true;
        _currentQuestionIndex = 0; 
        _rockWeight = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You weighed all your worries! Great job."), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _logFeeling(String stepName) async {
    final int level = _rockWeight.round(); 
    
    if (_isLogging) return;

    setState(() { _isLogging = true; });

    try {
      final childId = await UserStateService.getChildId();
      if (childId != null) {
        await LoggingService.logFeeling(
          childId: childId,
          characterId: '4', // Assuming Ricky is ID 4
          level: level, 
          context: context,
          investigation: [stepName], 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) { setState(() { _isLogging = false; }); }
    }
  }

  // ----------------------------------------------------
  // VISUAL BUILDER
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 0.0 (Top/Small) -> 1.0 (Bottom/Big)
    double progress = _rockWeight / _maxWeight;
    
    // Background Color shifts from Light Grey (Light) to Dark Slate (Heavy)
    Color bgColor = Color.lerp(Colors.grey.shade100, Colors.blueGrey.shade700, progress)!;
    Color textColor = progress > 0.5 ? Colors.white : Colors.blueGrey.shade900;
    
    const String rickyAsset = 'data/characters/ricky_the_rock.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('RICKY THE ROCK'),
        backgroundColor: bgColor, // Dynamic App Bar
        foregroundColor: textColor,
        elevation: 0,
        leading: widget.fromCharacterLibrary
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null, // Default back button behavior
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Smooth color transition
        color: bgColor,
        child: SafeArea(
          child: Column(
            children: [
              // --- TOP TEXT ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: "I'm RICKY. When you feel GUILTY, I feel HEAVY in your tummy. \n\n",
                      style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                      children: [
                        TextSpan(
                          text: "DRAG ME DOWN", 
                          style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.w900)
                        ),
                        const TextSpan(text: " to show a heavy feeling.\n"),
                        TextSpan(
                          text: "DRAG ME UP", 
                          style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900)
                        ),
                        const TextSpan(text: " to show a light feeling."),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // --- QUESTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  _questions[_currentQuestionIndex],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor, // Text color adapts to background
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // --- STATUS INDICATOR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withOpacity(0.5), width: 2)
                ),
                child: Text(
                  _getWeightStatus(_rockWeight),
                  style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.w900, 
                    color: textColor
                  ),
                ),
              ),

              // --- INTERACTIVE AREA (The "Scale") ---
              Expanded(
                child: GestureDetector(
                  // We use Vertical Drag to change the state
                  onVerticalDragUpdate: _handleDragUpdate,
                  child: Container(
                    color: Colors.transparent, // Transparent hit-test area
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Vertical Guide Line (Rope/Scale)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            color: textColor.withOpacity(0.3),
                          ),
                        ),
                        
                        // The Rock (Moves and Resizes)
                        Align(
                          // Alignment shifts from -0.8 (Top) to 0.8 (Bottom)
                          alignment: Alignment(0.0, -0.8 + (progress * 1.6)), 
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 50), // Responsive drag
                            // Size grows from 80px to 280px
                            width: 80 + (progress * 200), 
                            height: 80 + (progress * 200),
                            child: Image.asset(
                              rickyAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        // Interaction Hints
                        if (_rockWeight == 0)
                          Positioned(
                            top: 20,
                            child: Icon(Icons.arrow_downward, size: 40, color: textColor.withOpacity(0.5)),
                          ),
                        if (_rockWeight == _maxWeight)
                          Positioned(
                            bottom: 20,
                            child: Icon(Icons.arrow_upward, size: 40, color: textColor.withOpacity(0.5)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- NEXT BUTTON ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLogging ? null : _nextQuestion,
                        icon: _isLogging
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(_isLogging ? 'LOGGING...' : 'LOG THIS WEIGHT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: textColor, // Button adapts to theme
                          foregroundColor: bgColor,   // Text is inverted
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
                    // --- NEXT CHARACTER BUTTON (only show after all questions completed) ---
                    if (_allQuestionsCompleted) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => HeartbeatPage(fromCharacterLibrary: widget.fromCharacterLibrary)),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('NEXT CHARACTER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}