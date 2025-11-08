import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/parent_auth_service.dart';
import '../services/parent_data_service.dart';
import 'parent_profile.dart';
import 'forgot_password_page.dart';

class ParentLoginPage extends StatefulWidget {
  final String? childIdToLink;
  
  const ParentLoginPage({super.key, this.childIdToLink});

  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username!';
      });
      return;
    }
    
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Authenticate parent with backend
      final parentData = await ParentAuthService.loginParent(username, password, context);
      
      if (parentData != null) {
        // Check if there's a currently logged-in child
        final currentChildId = await UserStateService.getChildId();
        
        // If childIdToLink is provided, we're in "add another parent" mode
        // In this case, allow linking even if not already linked
        if (widget.childIdToLink != null) {
          // Save parent authentication state
          await UserStateService.saveParentAuthenticated(true);
          await UserStateService.saveParentId(parentData['id']);
          try {
            await ParentDataService.linkParentToChild(
              parentData['id'], 
              widget.childIdToLink!, 
              context
            );
            
            // Save this child as the active child
            await UserStateService.saveChildId(widget.childIdToLink!);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Parent account linked successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Just pop back - the parent profile page should reload automatically
              Navigator.of(context).pop();
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to link parent to child: ${e.toString()}';
              _isLoading = false;
            });
          }
          return;
        }
        
        // If a child is logged in (but not in "add another parent" mode), 
        // verify parent is linked to this child
        if (currentChildId != null) {
          final isLinked = await ParentDataService.isParentLinkedToChild(
            parentData['id'],
            currentChildId,
            context,
          );
          
          if (!isLinked) {
            // Get child name for better error message
            final childName = await UserStateService.getChildName() ?? 'this child';
            setState(() {
              _errorMessage = 'This parent account is not linked to $childName. Please use a parent account that is already associated with the current child, or ask an existing parent to add you.';
              _isLoading = false;
            });
            return;
          }
        }
        
        // Save parent authentication state
        await UserStateService.saveParentAuthenticated(true);
        await UserStateService.saveParentId(parentData['id']);
        
        // Normal login flow (no specific child to link)
        // Get parent's children from database
        final children = await ParentAuthService.getParentChildren(parentData['id'], context);
        
        if (children.isEmpty) {
          setState(() {
            _errorMessage = 'No children associated with this parent account. Please contact support or create a child profile.';
            _isLoading = false;
          });
          return;
        }
        
        // Use the first child
        final firstChild = children.first;
        final childId = firstChild['id'];
        
        // Link parent to child (this is idempotent, won't fail if already linked)
        try {
          await ParentAuthService.linkParentChild(parentData['id'], childId, context);
        } catch (e) {
          // Ignore if already linked
          print('Link parent-child: $e');
        }
        
        // Save child ID to state
        await UserStateService.saveChildId(childId);
        if (firstChild['name'] != null) {
          await UserStateService.saveChildName(firstChild['name']);
        }
        
        // Navigate to parent profile page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ParentProfilePage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        // Extract clean error message
        String errorMsg = e.toString();
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
        errorMsg = errorMsg.replaceFirst('Error: ', '');
        errorMsg = errorMsg.replaceAll(RegExp(r'^Login failed:\s*'), '');
        _errorMessage = errorMsg;
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
                      Icons.family_restroom,
                      size: 80,
                      color: Color(0xff4a90e2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Parent Access Text
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xff4a90e2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'PARENT ACCESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Show linking indicator if childIdToLink is provided
                  if (widget.childIdToLink != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Linking to child account',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  
                  // Login Input Card
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
                          'Enter Parent Credentials',
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
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password...',
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
                          onSubmitted: (_) => _login(),
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
                            onPressed: _isLoading ? null : _login,
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
                                    'Access Child Data',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Forgot password link
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff4a90e2),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Back to child mode button
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
                  const SizedBox(height: 20),
                  
                  // Info note
                  Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: const Text(
                        '👨‍👩‍👧‍👦 Parents can view their child\'s progress and character data here.',
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
