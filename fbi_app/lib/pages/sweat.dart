// lib/pages/samantha_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

import '../services/logging_service.dart';
import '../services/user_state_service.dart';
import '../services/character_service.dart';
import 'butterfly.dart';

// Mock CharacterConstants. DELETE IF USING SEPARATE FILE.
class CharacterConstants {
  static const String samanthaSweat = 'Samantha Sweat';
}

class SamanthaPage extends StatefulWidget {
  final bool fromCharacterLibrary;
  
  const SamanthaPage({Key? key, this.fromCharacterLibrary = false}) : super(key: key); 

  @override
  _SamanthaPageState createState() => _SamanthaPageState();
}

class _SamanthaPageState extends State<SamanthaPage> {
  
  int _heatLevel = 0; 
  static const int _maxLevel = 5; 
  bool _isLogging = false;
  bool _allQuestionsCompleted = false;
  String? _characterId;
  
  int _currentQuestionIndex = 0;
  final List<String> _questions = [
    "How warm do you feel right now?",
    "How warm do you feel outside on a very hot summer day?",
    "How warm do you feel after running and playing hard?",
    "How warm do you feel when you are very excited or a little nervous?",
  ];

  @override
  void initState() {
    super.initState();
    _loadCharacterId();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCharacterId() async {
    try {
      final characters = await CharacterService.getCharacters();
      final samantha = characters.firstWhere(
        (char) => char.name == 'Samantha Sweat',
        orElse: () => characters.first,
      );
      setState(() {
        _characterId = samantha.id;
      });
    } catch (e) {
      print('Error loading character ID: $e');
    }
  }
  
  // ----------------------------------------------------
  // HELPER: Status Text
  // ----------------------------------------------------
  String _getSweatStatus(int level) {
    if (level == 0) return "❄️ COOL AND DRY ❄️";
    if (level <= 1) return "😊 CALM";
    if (level <= 2) return "💧 A LITTLE WARM";
    if (level <= 4) return "🥵 HOT AND SWEATY";
    return "🚨 OVERHEATING! 🚨"; 
  }
  
  // ----------------------------------------------------
  // INTERACTION LOGIC (Simple Button Calls)
  // ----------------------------------------------------

  void _heatUp() {
    if (!_isLogging && _heatLevel < _maxLevel) {
      setState(() {
        _heatLevel++;
      });
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else if (_heatLevel == _maxLevel && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MAX HEAT! Tap Next Question.'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _coolDown() {
    if (_heatLevel > 0 && !_isLogging) {
      setState(() {
        _heatLevel--;
      });
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else if (_heatLevel == 0 && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already cool! ❄️'), duration: Duration(seconds: 1)),
        );
    }
  }

  void _nextQuestion() {
    _logFeeling('Q${_currentQuestionIndex + 1}: ${_questions[_currentQuestionIndex]} - Level: ${_heatLevel}');
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _heatLevel = 0;
        _allQuestionsCompleted = false;
      });
    } else {
      setState(() {
        _allQuestionsCompleted = true;
        _currentQuestionIndex = 0; 
        _heatLevel = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All questions answered! Starting over."), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _logFeeling(String stepName) async {
    final int level = _heatLevel; 
    if (_isLogging) return;

    setState(() { _isLogging = true; });

    try {
      final childId = await UserStateService.getChildId();
      if (childId != null && _characterId != null) {
        await LoggingService.logFeeling(
          childId: childId,
          characterId: _characterId!, 
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
  // THERMOSTAT WIDGET
  // ----------------------------------------------------
  Widget _buildThermostat(String assetPath) {
    final Color indicatorColor = Color.lerp(
      Colors.blue.shade300, 
      Colors.red.shade600, 
      _heatLevel / _maxLevel
    )!;
    
    const double tubeWidth = 60; 
    double fillPercent = _heatLevel / _maxLevel;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- HEAT UP BUTTON (Red Arrow) ---
          InkWell(
            onTap: _heatUp,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade400, width: 2),
              ),
              child: Icon(Icons.keyboard_arrow_up_rounded, size: 50, color: Colors.red.shade700),
            ),
          ),
          
          Text(
            "HEAT UP", 
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.red.shade700)
          ),
          
          const SizedBox(height: 10),

          // --- VISUAL THERMOMETER TUBE ---
          Expanded(
            child: Container(
              width: 140, 
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade900, width: 3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // White inner tube
                  Container(
                    width: tubeWidth,
                    height: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Animated Fill
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          heightFactor: fillPercent == 0 ? 0.05 : fillPercent, // Always show tiny bit
                          child: Container(
                            width: tubeWidth,
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(30)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Samantha Icon (Visual only)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: 90, height: 90,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: indicatorColor, width: 4),
                      ),
                      child: ClipOval(
                        child: Image.asset( 
                          assetPath, 
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- COOL DOWN BUTTON (Blue Arrow) ---
          Text(
            "COOL DOWN", 
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.blue.shade700)
          ),
          
          InkWell(
            onTap: _coolDown,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade400, width: 2),
              ),
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 50, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = Color.lerp(
      Colors.blue.shade300, 
      Colors.red.shade600, 
      _heatLevel / _maxLevel
    )!;
    
    const String samanthaAssetPath = 'data/characters/samantha_sweat.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAMANTHA SWEAT'),
        backgroundColor: Colors.blue.shade50,
        leading: widget.fromCharacterLibrary
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null, // Default back button behavior
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade50, Colors.cyan.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- TOP EXPLANATION ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: "I'm SAMANTHA SWEAT, your body's THERMOSTAT! I help you learn that sweating is how your body ",
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                        children: [
                          TextSpan(text: "COOLS DOWN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                          TextSpan(text: " when you're too hot. Use the arrows to set your heat level."),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // --- QUESTION ---
                  Text(
                    _questions[_currentQuestionIndex],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 10),

                  // --- STATUS ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'STATUS: ${_getSweatStatus(_heatLevel)}',
                      style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: indicatorColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // --- INTERACTIVE AREA ---
                  _buildThermostat(samanthaAssetPath),

                  const SizedBox(height: 20),

                  // --- NEXT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLogging || _heatLevel == 0 ? null : _nextQuestion,
                      icon: _isLogging
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward),
                      label: Text(_isLogging ? 'LOGGING...' : 'NEXT QUESTION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)
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
                            MaterialPageRoute(builder: (_) => BettyPage(fromCharacterLibrary: widget.fromCharacterLibrary)),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('NEXT CHARACTER'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
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
        ),
      ),
    );
  }
}