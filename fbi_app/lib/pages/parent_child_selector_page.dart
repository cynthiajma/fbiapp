import 'package:flutter/material.dart';
import '../services/parent_data_service.dart';
import '../services/user_state_service.dart';
import 'parent_view_child_page.dart';

class ParentChildSelectorPage extends StatefulWidget {
  const ParentChildSelectorPage({super.key});

  @override
  State<ParentChildSelectorPage> createState() => _ParentChildSelectorPageState();
}

class _ParentChildSelectorPageState extends State<ParentChildSelectorPage> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
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

      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load children: $e';
        _isLoading = false;
      });
    }
  }

  void _viewChild(Map<String, dynamic> child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentViewChildPage(
          childId: child['id'] as String,
          childName: child['name'] as String? ?? child['username'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'MY CHILDREN',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: _isLoading
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Children Linked',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'You haven\'t linked any children to your account yet. Create a child account or link an existing one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        return _ChildCard(
                          child: child,
                          onTap: () => _viewChild(child),
                        );
                      },
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xff4a90e2).withOpacity(0.1),
                child: Icon(
                  Icons.child_care,
                  size: 32,
                  color: const Color(0xff4a90e2),
                ),
              ),
              const SizedBox(width: 16),
              // Child info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (age != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Age: $age',
                        style: TextStyle(
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
      ),
    );
  }
}

