import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/parent_data_service.dart';
import '../services/parent_auth_service.dart';
import '../services/user_state_service.dart';
import '../services/avatar_storage_service.dart';
import 'parent_view_child_page.dart';
import 'parent_login_page.dart';
import 'parent_signup_page.dart';

class ParentChildSelectorPage extends StatefulWidget {
  const ParentChildSelectorPage({super.key});

  @override
  State<ParentChildSelectorPage> createState() => _ParentChildSelectorPageState();
}

class _ParentChildSelectorPageState extends State<ParentChildSelectorPage> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _parentUsername;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _loadParentUsername();
  }

  Future<void> _loadParentUsername() async {
    try {
      final parentId = await UserStateService.getParentId();
      if (parentId != null) {
        final parentProfile = await ParentAuthService.getParentProfile(parentId, context);
        if (mounted) {
          setState(() {
            _parentUsername = parentProfile?['username'] as String?;
          });
        }
      }
    } catch (e) {
      // Silently fail - username tag is optional
    }
  }

  Future<void> _loadChildren() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current parent ID
      final parentId = await UserStateService.getParentId();
      if (parentId == null) {
        setState(() {
          _errorMessage = 'No parent logged in';
          _isLoading = false;
        });
        return;
      }

      // Load children linked to this parent
      final children = await ParentDataService.getParentChildren(parentId, context);
      final enrichedChildren = await Future.wait(
        children.map((child) async {
          final childId = child['id'] as String;
          final avatarSvg = await AvatarStorageService.getAvatarSvg(childId);
          return {
            ...child,
            'avatarSvg': avatarSvg,
            'name': child['username'],
          };
        }).toList(),
      );

      if (!mounted) return;

      setState(() {
        _children = enrichedChildren;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load children: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _viewChild(Map<String, dynamic> child) async {
    // Save child to state before navigating to ensure consistency
    final childId = child['id'] as String;
    final childName = child['name'] as String? ?? child['username'] as String;
    
    if (mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentViewChildPage(
            childId: childId,
            childName: childName,
          ),
        ),
      );
    }
  }

  void _showAddParentDialog() {
    if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No children available. Please link a child first.')),
      );
      return;
    }

    // Show dialog to select which child to add a parent to
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.family_restroom, color: Color(0xff4a90e2)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Add a Parent'),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select which child to add a parent to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _children.length,
                    itemBuilder: (context, index) {
                      final child = _children[index];
                      final name = child['name'] as String? ?? child['username'] as String;
                      return ListTile(
                        title: Text(name),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showAddParentOptions(child['id'] as String, name);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddParentOptions(String childId, String childName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.family_restroom, color: Color(0xff4a90e2)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Parent to $childName',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how to add another parent:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '• Create a new account and link it automatically\n'
              '• Or login with an existing parent account to link it',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentLoginPage(childIdToLink: childId),
                ),
              );
              // Reload children if linking was successful
              if (result == true && mounted) {
                _loadChildren();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentSignupPage(childId: childId),
                ),
              );
              // Reload children if linking was successful
              if (result == true && mounted) {
                _loadChildren();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4a90e2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

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
          _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChildren,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _children.isEmpty
                      ? SafeArea(
                          child: Center(
                            child: Transform.rotate(
                              angle: -1 * 3.1416 / 180,
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      offset: Offset(3, 3),
                                      blurRadius: 5,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.child_care,
                                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Children Linked',
                            style: TextStyle(
                                              fontFamily: 'SpecialElite',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'You haven\'t linked any children to your account yet. Create a child account or link an existing one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
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
                        )
                      : SafeArea(
                          child: RefreshIndicator(
                            onRefresh: _loadChildren,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Column(
                                children: [
                                  // Top bar
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          icon: const Icon(Icons.arrow_back, color: Color(0xff4a90e2), size: 24),
                                          onPressed: () => Navigator.of(context).pop(),
                                          tooltip: 'Back',
                                        ),
                                      ),
                                      Row(
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
                                              icon: const Icon(Icons.person_add, color: Colors.brown, size: 24),
                                              onPressed: _showAddParentDialog,
                                              tooltip: 'Add a parent',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Title
                                  Transform.rotate(
                                    angle: -1.5 * 3.1416 / 180,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8DC),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            offset: Offset(3, 3),
                                            blurRadius: 5,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          const Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Icons.family_restroom,
                                                  size: 48,
                                                  color: Color(0xff4a90e2),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'MY CHILDREN',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontFamily: 'SpecialElite',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 28,
                                                    color: Colors.black87,
                                                    height: 1.1,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${_children.length} ${_children.length == 1 ? 'Child' : 'Children'}',
                                                  style: TextStyle(
                                                    fontFamily: 'SpecialElite',
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Children list
                                  for (int i = 0; i < _children.length; i++) ...[
                                    Transform.rotate(
                                      angle: (i % 2 == 0 ? 1 : -1) * 1.5 * 3.1416 / 180,
                                      child: _ChildCard(
                                        child: _children[i],
                                        onTap: () => _viewChild(_children[i]),
                                      ),
                                    ),
                                    if (i != _children.length - 1) const SizedBox(height: 16),
                                  ],
                                  const SizedBox(height: 24),
                                  // Parent username tag
                                  if (_parentUsername != null)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff4a90e2).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Parent: @$_parentUsername',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
        ],
                    ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;

  const _ChildCard({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = child['name'] as String? ?? child['username'] as String;
    final username = child['username'] as String;
    final age = child['age'] as int?;
    final avatarSvg = child['avatarSvg'] as String?;

    return GestureDetector(
        onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              offset: Offset(3, 3),
              blurRadius: 5,
              color: Colors.black26,
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 8,
              left: 10,
              child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              // Avatar
              _ChildAvatar(svgData: avatarSvg),
              const SizedBox(width: 16),
              // Child info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          name.toUpperCase(),
                      style: const TextStyle(
                            fontFamily: 'SpecialElite',
                        fontSize: 20,
                            fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                            fontFamily: 'SpecialElite',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (age != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Age: $age',
                        style: TextStyle(
                              fontFamily: 'SpecialElite',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final String? svgData;
  const _ChildAvatar({required this.svgData});

  @override
  Widget build(BuildContext context) {
    if (svgData == null || svgData!.isEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundColor: const Color(0xff4a90e2).withOpacity(0.1),
        child: const Icon(
          Icons.child_care,
          size: 32,
          color: Color(0xff4a90e2),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(2, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: ClipOval(
        child: Builder(
          builder: (context) {
            try {
              return SvgPicture.string(
                svgData!,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                colorFilter: null,
              );
            } catch (e) {
              // If SVG fails to render, show default icon
              return const Icon(
                Icons.child_care,
                size: 32,
                color: Color(0xff4a90e2),
              );
            }
          },
        ),
      ),
    );
  }
}


