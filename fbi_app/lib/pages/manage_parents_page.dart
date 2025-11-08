import 'package:flutter/material.dart';
import '../services/child_data_service.dart';
import 'parent_signup_page.dart';

class ManageParentsPage extends StatefulWidget {
  final String childId;
  final String childName;

  const ManageParentsPage({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ManageParentsPage> createState() => _ManageParentsPageState();
}

class _ManageParentsPageState extends State<ManageParentsPage> {
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load child profile to get linked parents
      final childProfile = await ChildDataService.getChildProfile(widget.childId, context);
      
      if (childProfile != null) {
        // The backend Child type has a parents field that returns linked parents
        // We need to query it via the childProfile
        final parents = childProfile['parents'] as List<dynamic>?;
        
        setState(() {
          _parents = parents?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load child profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load parents: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddParentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Color(0xff4a90e2)),
            SizedBox(width: 8),
            Text('Add Parent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to add a parent to ${widget.childName}\'s account?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _linkExistingParent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Link Existing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentSignupPage(childId: widget.childId),
                ),
              ).then((_) => _loadParents());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4a90e2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create New'),
          ),
        ],
      ),
    );
  }

  void _linkExistingParent() {
    final usernameController = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Link Existing Parent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the username of the parent account you want to link:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
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
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  errorMsg!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text.trim();
                if (username.isEmpty) {
                  setDialogState(() {
                    errorMsg = 'Please enter a username';
                  });
                  return;
                }

                try {
                  // This would require a getParentByUsername method similar to getChildByUsername
                  // For now, we'll need the parent ID. In a real app, you'd implement this.
                  // For simplicity, show a message that they need to use parent ID
                  setDialogState(() {
                    errorMsg = 'Feature coming soon. For now, create a new parent account.';
                  });
                  
                  // Future implementation:
                  // final parent = await ParentDataService.getParentByUsername(username, context);
                  // if (parent == null) {
                  //   setDialogState(() {
                  //     errorMsg = 'Parent username not found';
                  //   });
                  //   return;
                  // }
                  // await ParentDataService.linkParentToChild(parent['id'], widget.childId, context);
                  // Navigator.of(context).pop();
                  // _loadParents();
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(content: Text('Parent linked successfully!')),
                  // );
                } catch (e) {
                  setDialogState(() {
                    errorMsg = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4a90e2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Link'),
            ),
          ],
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
          'MANAGE PARENTS',
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
                        onPressed: _loadParents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header section
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xff4a90e2).withOpacity(0.1),
                            child: const Icon(
                              Icons.child_care,
                              size: 30,
                              color: Color(0xff4a90e2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.childName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_parents.length} parent(s) linked',
                                  style: TextStyle(
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

                    // Add parent button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddParentDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Parent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4a90e2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Parents list
                    if (_parents.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.family_restroom,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No Parents Linked',
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
                                  'Add a parent account to allow monitoring of ${widget.childName}\'s progress.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _parents.length,
                          itemBuilder: (context, index) {
                            final parent = _parents[index];
                            return _ParentCard(parent: parent);
                          },
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  final Map<String, dynamic> parent;

  const _ParentCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    final username = parent['username'] as String;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xff4a90e2).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 28,
                color: Color(0xff4a90e2),
              ),
            ),
            const SizedBox(width: 16),
            // Parent info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Linked',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

