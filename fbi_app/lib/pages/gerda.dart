// lib/pages/gerda_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

import '../services/logging_service.dart';
import '../services/user_state_service.dart';
import 'rock.dart';

// Mock Constants (Delete if using separate file)
class CharacterConstants {
  static const String gerdaGottaGo = 'Gerda Gotta Go';
}

class GerdaPage extends StatefulWidget {
  final bool fromCharacterLibrary;
  
  const GerdaPage({Key? key, this.fromCharacterLibrary = false}) : super(key: key); 

  @override
  _GerdaPageState createState() => _GerdaPageState();
}

class _GerdaPageState extends State<GerdaPage> with SingleTickerProviderStateMixin {
  
  double _fillLevel = 0.0; 
  bool _isLogging = false;
  bool _allQuestionsCompleted = false;
  
  late AnimationController _shakeController;
  
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    "How full does your Gerda tummy feel right now?",
    "How full does your Gerda feel after drinking a big glass of water?",
    "How full does your Gerda feel when you are playing a game and don't want to stop?",
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // HELPER: Descriptive Status
  // ----------------------------------------------------
  String _getUrgencyStatus(double level) {
    if (level < 0.2) return "EMPTY (Good to go!)";
    if (level < 0.5) return "COULD GO (Maybe later)";
    if (level < 0.8) return "NEED TO GO (Find a bathroom)";
    return "⚠️ EMERGENCY! (GOTTA GO!) ⚠️"; 
  }

  // ----------------------------------------------------
  // INTERACTION LOGIC: Liquid Drag
  // ----------------------------------------------------

  void _handleDragUpdate(DragUpdateDetails details, double maxHeight) {
    if (_isLogging) return;

    setState(() {
      double delta = -(details.delta.dy) / maxHeight; 
      _fillLevel += delta;
      
      if (_fillLevel > 1.0) _fillLevel = 1.0;
      if (_fillLevel < 0.0) _fillLevel = 0.0;

      if (_fillLevel > 0.8) {
        if (!_shakeController.isAnimating) _shakeController.repeat(reverse: true);
      } else {
        _shakeController.stop();
        _shakeController.reset();
      }
    });
  }

  void _nextQuestion() {
    _logFeeling('Q${_currentQuestionIndex + 1}: ${_questions[_currentQuestionIndex]} - Fullness: ${(_fillLevel * 100).round()}%');
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _fillLevel = 0.0; 
        _shakeController.stop();
      });
    } else {
      setState(() {
        _allQuestionsCompleted = true;
        _currentQuestionIndex = 0; 
        _fillLevel = 0.0;
        _shakeController.stop();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All finished! You listened to your body."), duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _logFeeling(String stepName) async {
    final int level = (_fillLevel * 10).round(); 
    
    if (_isLogging) return;

    setState(() { _isLogging = true; });

    try {
      final childId = await UserStateService.getChildId();
      if (childId != null) {
        await LoggingService.logFeeling(
          childId: childId,
          characterId: '5', 
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
    Color liquidColor = Color.lerp(Colors.lightBlue.shade100, Colors.amber.shade400, _fillLevel)!;
    const String gerdaAsset = 'data/characters/gerda_gotta_go.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('GERDA GOTTA GO'),
        backgroundColor: Colors.amber.shade100,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          double tankHeight = constraints.maxHeight * 0.55; // Slightly reduced to fit intro text

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  // --- TOP EXPLANATION TEXT (NEW) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: "I'm ",
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.brown.shade800),
                          children: [
                            TextSpan(text: "GERDA GOTTA GO", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber.shade800)),
                            TextSpan(text: "! I'm the feeling you get when your bladder is full and you "),
                            TextSpan(text: "NEED TO PEE", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amber.shade800)),
                            TextSpan(text: ". Drag up to show how full you feel!"),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // --- CURRENT QUESTION & STATUS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          _questions[_currentQuestionIndex],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Text(
                            _getUrgencyStatus(_fillLevel),
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _fillLevel > 0.8 ? Colors.red : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- INTERACTIVE TANK ---
                  Expanded(
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) => _handleDragUpdate(details, tankHeight),
                      child: Container(
                        color: Colors.transparent, 
                        child: Center(
                          child: Container(
                            width: 200,
                            height: tankHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100, 
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              border: Border.all(color: Colors.grey.shade400, width: 3),
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // 1. Liquid Fill
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 50),
                                  width: double.infinity,
                                  height: tankHeight * _fillLevel, 
                                  decoration: BoxDecoration(
                                    color: liquidColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(27),
                                      bottomRight: Radius.circular(27),
                                    ),
                                  ),
                                ),

                                // 2. Floating Gerda
                                Positioned(
                                  bottom: (tankHeight * _fillLevel) - 40, 
                                  child: AnimatedBuilder(
                                    animation: _shakeController,
                                    builder: (context, child) {
                                      double offset = sin(_shakeController.value * pi * 4) * 5;
                                      return Transform.translate(
                                        offset: Offset(offset, 0),
                                        child: Image.asset(
                                          gerdaAsset,
                                          height: 120,
                                          width: 120,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // 3. Guide Arrows
                                if (_fillLevel == 0)
                                  Positioned(
                                    top: 50,
                                    child: Column(
                                      children: [
                                        Icon(Icons.arrow_upward, size: 40, color: Colors.grey.shade300),
                                        Text("DRAG UP\nTO FILL", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: Colors.grey.shade400, fontWeight: FontWeight.bold))
                                      ],
                                    )
                                  ),
                              ],
                            ),
                          ),
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
                                : const Icon(Icons.arrow_forward),
                            label: Text(_isLogging ? 'LOGGING...' : 'NEXT QUESTION'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
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
                        // --- NEXT CHARACTER BUTTON (only show after all questions completed) ---
                        if (_allQuestionsCompleted) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => RickyPage(fromCharacterLibrary: widget.fromCharacterLibrary)),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('NEXT CHARACTER'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
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
          );
        },
      ),
    );
  }
}