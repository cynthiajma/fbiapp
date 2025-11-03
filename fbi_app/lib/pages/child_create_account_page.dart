import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/child_auth_service.dart';
import '../home.dart';
import 'child_login_page.dart';

class ChildCreateAccountPage extends StatefulWidget {
  const ChildCreateAccountPage({super.key});

  @override
  State<ChildCreateAccountPage> createState() => _ChildCreateAccountPageState();
}

class _ChildCreateAccountPageState extends State<ChildCreateAccountPage> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username!';
      });
      return;
    }
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name!';
      });
      return;
    }

    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age < 0) {
        setState(() {
          _errorMessage = 'Please enter a valid age (or leave it empty)!';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create the child account
      final childData = await ChildAuthService.createChild(
        username,
        name.isEmpty ? null : name,
        age,
        context,
      );
      
      if (childData == null) {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
        return;
      }
      
      // Save the child's data to state
      await UserStateService.saveChildName(childData['name'] ?? name);
      await UserStateService.saveChildId(childData['id']);
      
      // Navigate to home page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating account: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/corkboard.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or Image
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(2, 4),
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Color(0xffe67268),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Create Account Text
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xffe67268),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Create Your Detective Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(2, 4),
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Enter Your Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username (e.g., alice_detective)',
                            labelText: 'Username *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: (_) => _createAccount(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            labelText: 'Name *',
                            prefixIcon: const Icon(Icons.badge),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: (_) => _createAccount(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            hintText: 'Your age (optional)',
                            labelText: 'Age',
                            prefixIcon: const Icon(Icons.cake),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _createAccount(),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffe67268),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Back to login button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const ChildLoginPage()),
                      );
                    },
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Info note
                  Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: const Text(
                        '🕵️‍♀️ Create your detective profile to start investigating!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SpecialElite',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

