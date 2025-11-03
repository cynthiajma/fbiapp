import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/parent_auth_service.dart';
import '../services/child_auth_service.dart';
import '../home.dart';
import 'parent_profile.dart';
import 'parent_login_page.dart';

class ParentCreateAccountPage extends StatefulWidget {
  const ParentCreateAccountPage({super.key});

  @override
  State<ParentCreateAccountPage> createState() => _ParentCreateAccountPageState();
}

class _ParentCreateAccountPageState extends State<ParentCreateAccountPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _childUsernameController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingChild = false;
  String? _errorMessage;
  String? _childSearchError;
  Map<String, dynamic>? _foundChild;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _childUsernameController.dispose();
    super.dispose();
  }

  Future<void> _searchChild() async {
    final childUsername = _childUsernameController.text.trim();
    
    if (childUsername.isEmpty) {
      setState(() {
        _childSearchError = 'Please enter a child username';
        _foundChild = null;
      });
      return;
    }

    setState(() {
      _isSearchingChild = true;
      _childSearchError = null;
      _foundChild = null;
    });

    try {
      final childData = await ChildAuthService.getChildByUsername(childUsername, context);
      // ERROR HANDLING IF CHILD NOT FOUND
      if (childData == null) {
        setState(() {
          _childSearchError = 'Child not found. Please check the username.';
          _isSearchingChild = false;
        });
      } else {
        setState(() {
          _foundChild = childData;
          _childSearchError = null;
          _isSearchingChild = false;
        });
      }
    } catch (e) {
      // Need an another error handling here if child not found
      setState(() {
        _childSearchError = 'Error searching for child: ${e.toString().replaceFirst('Exception: ', '')}';
        _foundChild = null;
        _isSearchingChild = false;
      });
    }
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username!';
      });
      return;
    }
    
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password!';
      });
      return;
    }

    if (password.length < 4) {
      setState(() {
        _errorMessage = 'Password must be at least 4 characters long!';
      });
      return;
    }
    
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create the parent account with ability to link child
      final parentData = await ParentAuthService.createParent(
        username,
        password,
        _foundChild?['id'],
        context,
      );
      
      if (parentData == null) {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
        return;
      }
      
      // Save authetnication of parent
      await UserStateService.saveParentAuthenticated(true);
      await UserStateService.saveParentId(parentData['id']);
      
      // If a child was linked, save the child's data to state
      if (_foundChild != null) {
        await UserStateService.saveChildId(_foundChild!['id']);
        if (_foundChild!['name'] != null) {
          await UserStateService.saveChildName(_foundChild!['name']);
        }
      }
      
      // Once mounted navigate to parent profile page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ParentProfilePage()),
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
                  // Parent Icon
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
                      color: Color(0xff4a90e2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Create Account Text
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xff4a90e2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'CREATE PARENT ACCOUNT',
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
                          'Parent Information',
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
                            hintText: 'Username...',
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
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password...',
                            labelText: 'Password *',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
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
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm Password...',
                            labelText: 'Confirm Password *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: (_) => _createAccount(),
                        ),
                        const SizedBox(height: 32),
                        
                        // Divider
                        const Divider(thickness: 1),
                        const SizedBox(height: 16),
                        
                        // Link to Child Section
                        const Text(
                          'Link to Existing Child (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter your child\'s username to link them to your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _childUsernameController,
                                decoration: InputDecoration(
                                  hintText: 'Child username...',
                                  prefixIcon: const Icon(Icons.child_care),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onSubmitted: (_) => _searchChild(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isSearchingChild ? null : _searchChild,
                              icon: _isSearchingChild
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff4a90e2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        if (_childSearchError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Text(
                                _childSearchError!,
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                            ),
                          ),
                        if (_foundChild != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Child Found: ${_foundChild!['name'] ?? _foundChild!['username']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        if (_foundChild!['age'] != null)
                                          Text(
                                            'Age: ${_foundChild!['age']}',
                                            style: TextStyle(color: Colors.green[700], fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _foundChild = null;
                                        _childUsernameController.clear();
                                      });
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
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
                              backgroundColor: const Color(0xff4a90e2),
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
                  
                  // Button to navigate to login page
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const ParentLoginPage()),
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
                  
                  // button to navigate to child mode
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Back to Child Mode',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
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

