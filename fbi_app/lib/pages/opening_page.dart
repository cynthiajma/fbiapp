import 'package:flutter/material.dart';
import 'dart:math';
import 'login_selection_page.dart';

class OpeningPage extends StatefulWidget {
  const OpeningPage({super.key});

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _angle;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _angle = Tween(begin: 0.0, end: -pi / 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginSelectionPage(),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final briefcaseWidth = screenWidth * 0.75;
    final briefcaseHeight = briefcaseWidth * 0.55;

    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Bottom half of briefcase
                Container(
                  width: briefcaseWidth,
                  height: briefcaseHeight,
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Center(
                      child: Image.asset(
                        'assets/images/fbi_logo.png',
                        width: briefcaseWidth * 0.4,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Top lid (rotates open)
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateX(_angle.value),
                  child: Container(
                    width: briefcaseWidth,
                    height: briefcaseHeight,
                    decoration: BoxDecoration(
                      color: Colors.brown[900],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Handle
                Positioned(
                  top: -briefcaseHeight * 0.15, // slightly above lid
                  child: Container(
                    width: briefcaseWidth * 0.4,
                    height: briefcaseHeight * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Left gold clip
                Positioned(
                  top: briefcaseHeight * 0.05,
                  left: -briefcaseWidth * 0.02,
                  child: Container(
                    width: briefcaseWidth * 0.05,
                    height: briefcaseHeight * 0.15,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.yellow, Colors.amber, Colors.white, Colors.amber],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right gold clip
                Positioned(
                  top: briefcaseHeight * 0.05,
                  right: -briefcaseWidth * 0.02,
                  child: Container(
                    width: briefcaseWidth * 0.05,
                    height: briefcaseHeight * 0.15,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.yellow, Colors.amber, Colors.white, Colors.amber],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

