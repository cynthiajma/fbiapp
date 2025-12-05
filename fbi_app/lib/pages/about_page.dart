import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          SafeArea(
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Back',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'About',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            fontWeight: FontWeight.w700,
                            fontSize: 36,
                            color: Colors.black87,
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 3),
                                blurRadius: 2,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DC).withOpacity(0.95), // Very light tan/cream
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'About This App',
                            child: const Text(
                              'Feelings and Body Investigation (FBI) is an educational app designed to help children learn about their bodies and emotions through interactive character-based experiences. Developed as part of CompSci 408 at Duke University with Dr. Nancy Zucker, Professor of Psychiatry and Behavioral Sciences at Duke. Based off her practical handbook, “Treating Functional Abdominal Pain in Children.”',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSection(
                            title: 'Development Team',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTeamMember('Cynthia Ma'),
                                _buildTeamMember('Linda Wang'),
                                _buildTeamMember('Sean Rogers'),
                                _buildTeamMember('Kyle McCutchen'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSection(
                            title: 'Institution',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Duke University',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This project was developed as part of CompSci 408 at Duke University. ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'SpecialElite',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            shadows: const [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 2,
                color: Colors.white70,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTeamMember(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}

