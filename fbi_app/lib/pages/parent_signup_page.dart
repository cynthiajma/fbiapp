import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../services/parent_auth_service.dart';
import '../services/child_auth_service.dart';
import '../services/user_state_service.dart';
import 'parent_login_page.dart';

class ParentSignupPage extends StatefulWidget {
  final String? childId;
  
  const ParentSignupPage({super.key, this.childId});

  @override
  State<ParentSignupPage> createState() => _ParentSignupPageState();
}

class _ParentSignupPageState extends State<ParentSignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _childUsernameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _childName;

  @override
  void initState() {
    super.initState();
    if (widget.childId != null) {
      _loadChildName();
    }
  }

  Future<void> _loadChildName() async {
    try {
      final childProfile = await ChildAuthService.getChildById(widget.childId!, context);
      if (childProfile != null) {
        setState(() {
          _childName = childProfile['name'] as String? ?? childProfile['username'] as String;
        });
      }
    } catch (e) {
      // If we can't load the child name, just continue without it
      print('Error loading child name: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _childUsernameController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final childUsername = _childUsernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username';
      });
      return;
    }
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email address';
      });
      return;
    }
    if (!EmailValidator.validate(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? childId = widget.childId; // Use provided childId if available

      // If no childId was provided to the widget, check if user entered a child username
      if (childId == null && childUsername.isNotEmpty) {
        final child = await ChildAuthService.getChildByUsername(childUsername, context);
        if (child == null) {
          setState(() {
            _errorMessage = 'Child username not found';
            _isLoading = false;
          });
          return;
        }
        childId = child['id'] as String?;
      }

      final parent = await ParentAuthService.createParent(
        username: username,
        email: email,
        password: password,
        childId: childId,
        context: context,
      );

      if (parent == null) {
        setState(() {
          _errorMessage = 'Failed to create parent account';
          _isLoading = false;
        });
        return;
      }

      // If childId is provided, we're in "add another parent" mode
      // DO NOT save the newly created parent's ID - preserve the current parent's ID
      // We only link the new parent to the child, but keep viewing as the original parent
      if (childId != null) {
        // Parent is linked to child, but we don't change the active logged-in parent
        // This preserves the originally logged-in parent's ID so they can continue viewing
        // their own children after adding another parent.

        if (mounted) {
          final username = parent['username'] as String? ?? 'parent';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Parent "$username" created and linked successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Pop back with a result to indicate that linking was successful
          // This will trigger a reload in the parent child selector page
          Navigator.of(context).pop(true);
        }
      } else {
        // If no childId, this is a normal signup - save the parent state
        await UserStateService.saveParentAuthenticated(true);
        await UserStateService.saveParentId(parent['id']);
        // If not linked, send them to login with a hint
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Now log in and link a child.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => ParentLoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        String msg = e.toString().replaceFirst('Exception: ', '');
        
        // Provide user-friendly error messages for common cases
        if (msg.toLowerCase().contains('email') && 
            (msg.toLowerCase().contains('already') || 
             msg.toLowerCase().contains('registered') ||
             msg.toLowerCase().contains('exists') ||
             msg.toLowerCase().contains('duplicate'))) {
          _errorMessage = 'This email address is already registered. Please use a different email or try logging in instead.';
        } else if ((msg.toLowerCase().contains('username') && 
                   (msg.toLowerCase().contains('already') || 
                    msg.toLowerCase().contains('taken') ||
                    msg.toLowerCase().contains('duplicate'))) ||
                   msg.toLowerCase().contains('duplicate key') ||
                   msg.toLowerCase().contains('unique constraint')) {
          _errorMessage = 'This username is already taken. Please choose a different username.';
        } else {
          _errorMessage = msg;
        }
        
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
                  const SizedBox(height: 16),
                  // Show linking indicator if childId is provided
                  if (widget.childId != null)
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
                            _childName != null
                                ? 'Linking to: $_childName'
                                : 'Linking to child account',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
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
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Parent username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
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
                        ),
                        const SizedBox(height: 16),
                        // Only show child username field if childId not provided
                        if (widget.childId == null) ...[
                          TextField(
                            controller: _childUsernameController,
                            decoration: InputDecoration(
                              hintText: 'Child username to link (optional)',
                              prefixIcon: const Icon(Icons.child_care),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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
                            onPressed: _isLoading ? null : _signup,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => ParentLoginPage()),
                            );
                          },
                          child: const Text('Already have an account? Log in'),
                        ),
                      ],
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


