import 'package:flutter/material.dart';
import 'services/logging_service.dart';
import 'services/user_state_service.dart';

class HeartbeatPage extends StatefulWidget {
  const HeartbeatPage({super.key});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage>
    with SingleTickerProviderStateMixin {
  double _heartbeatSpeed = 0.5;
  late AnimationController _controller;
  bool _isLogging = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      
      // For now, hardcode characterId to 1 (Henry the Heartbeat)
      const characterId = '1';
      
      final result = await LoggingService.logFeeling(
        childId: childId,
        characterId: characterId,
        level: level,
        context: context,
        // investigation will be added as a feature in the future
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feeling logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging feeling: $e'),
            backgroundColor: Colors.red,
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
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
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
                      Icon(Icons.emoji_nature_rounded, color: Colors.red),
                      SizedBox(width: 5),
                      Text('SLOW LIKE A TURTLE'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('FAST LIKE A RABBIT'),
                      SizedBox(width: 5),
                      Icon(Icons.pets_rounded, color: Colors.red),
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
                activeColor: Colors.redAccent,
                inactiveColor: Colors.red[100],
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
                    : const Icon(Icons.play_arrow),
                label: Text(_isLogging ? 'Saving...' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLogging
                      ? Colors.grey
                      : Colors.greenAccent,
                  foregroundColor: Colors.black,
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
