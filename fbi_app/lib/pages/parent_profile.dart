import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../features/character.dart';
import '../widgets/char_row.dart';
import '../services/user_state_service.dart';
import '../services/child_data_service.dart';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  String _childName = 'Loading...';
  List<Character> _characters = [];
  List<Map<String, dynamic>> _characterLibrary = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _childId;

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    try {
      // Get current child ID
      final childId = await UserStateService.getChildId();
      if (childId == null) {
        setState(() {
          _errorMessage = 'No child selected';
          _isLoading = false;
        });
        return;
      }

      // Load child profile and logs
      if (!mounted) return;
      final childProfile = await ChildDataService.getChildProfile(childId, context);
      if (!mounted) return;
      final childLogs = await ChildDataService.getChildLogs(childId, context);
      if (!mounted) return;
      final characterLibrary = await ChildDataService.getCharacterLibrary(context);

      if (childProfile != null) {
        setState(() {
          _childName = childProfile['name'] ?? 'Unknown Child';
        });
      }

      // Process logs to create individual log entries
      final logEntries = ChildDataService.processLogsToIndividualEntries(childLogs, characterLibrary);
      
      // Convert to Character objects for display
      final characters = logEntries.map((entry) {
        final characterName = entry['characterName'] as String;
        final level = entry['level'] as int;
        final progress = entry['progress'] as double;
        final date = entry['date'] as DateTime;
        
        return Character(
          name: characterName,
          imageAsset: 'data/characters/${ChildDataService.getCharacterImagePath(characterName)}',
          progress: progress,
          date: date,
          averageLevel: level, // This is now the individual level, not average
        );
      }).toList();

      setState(() {
        _childId = childId;
        _characters = characters;
        _characterLibrary = characterLibrary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showExportDialog() async {
    if (_childId == null) return;

    String? selectedCharacter;
    DateTime? startDate;
    DateTime? endDate;
    bool filterByCharacter = false;
    bool filterByTime = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Export Logs as CSV'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter by Character
                    CheckboxListTile(
                      title: const Text('Filter by Character'),
                      value: filterByCharacter,
                      onChanged: (value) {
                        setDialogState(() {
                          filterByCharacter = value ?? false;
                          if (!filterByCharacter) {
                            selectedCharacter = null;
                          }
                        });
                      },
                    ),
                    if (filterByCharacter) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCharacter,
                        decoration: const InputDecoration(
                          labelText: 'Select Character',
                          border: OutlineInputBorder(),
                        ),
                        items: _characterLibrary.map((char) {
                          final name = char['name'] as String? ?? 'Unknown';
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCharacter = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Filter by Time
                    CheckboxListTile(
                      title: const Text('Filter by Logging Time'),
                      value: filterByTime,
                      onChanged: (value) {
                        setDialogState(() {
                          filterByTime = value ?? false;
                          if (!filterByTime) {
                            startDate = null;
                            endDate = null;
                          }
                        });
                      },
                    ),
                    if (filterByTime) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(startDate == null
                            ? 'Not selected'
                            : '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('End Date'),
                        subtitle: Text(endDate == null
                            ? 'Not selected'
                            : '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'character': filterByCharacter ? selectedCharacter : null,
                      'startDate': filterByTime ? startDate : null,
                      'endDate': filterByTime ? endDate : null,
                    });
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _exportToCsv(
        characterName: result['character'] as String?,
        startDate: result['startDate'] as DateTime?,
        endDate: result['endDate'] as DateTime?,
      );
    }
  }

  Future<void> _exportToCsv({
    String? characterName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_childId == null) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Prepare time filter strings
      String? startTimeStr;
      String? endTimeStr;
      
      if (startDate != null) {
        startTimeStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T00:00:00.000Z';
      }
      if (endDate != null) {
        // Set to end of day
        final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        endTimeStr = endDateTime.toIso8601String();
      }

      // Fetch logs with filters
      final childLogs = await ChildDataService.getChildLogs(
        _childId!,
        context,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      // Filter by character if specified
      List<Map<String, dynamic>> filteredLogs = childLogs;
      if (characterName != null) {
        filteredLogs = childLogs.where((log) {
          final logCharacterName = log['characterName'] as String?;
          return logCharacterName == characterName;
        }).toList();
      }

      if (filteredLogs.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logs found matching the selected filters')),
        );
        return;
      }

      // Generate CSV content
      final csvBuffer = StringBuffer();
      
      // CSV Header
      csvBuffer.writeln('Log ID,Character Name,Level,Timestamp');
      
      // CSV Rows
      for (final log in filteredLogs) {
        final logId = log['id'] ?? '';
        final charName = log['characterName'] ?? '';
        final level = log['level'] ?? '';
        final timestamp = log['timestamp'] ?? '';
        
        // Escape commas and quotes in CSV
        String escapeCsv(String value) {
          if (value.contains(',') || value.contains('"') || value.contains('\n')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        }
        
        csvBuffer.writeln('${escapeCsv(logId.toString())},'
            '${escapeCsv(charName.toString())},'
            '${escapeCsv(level.toString())},'
            '${escapeCsv(timestamp.toString())}');
      }

      final csvContent = csvBuffer.toString();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'child_logs_${_childName.replaceAll(' ', '_')}_$timestamp.csv';

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Save to temporary file and share
      await _downloadFileNative(csvContent, fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exported successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  Future<void> _downloadFileNative(String content, String fileName) async {
    // Native implementation using path_provider and share_plus
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: 'Child Logs Export - $_childName',
      text: 'Exported logs for $_childName',
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
                            onPressed: _loadChildData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SafeArea(
                      child: RefreshIndicator(
                        onRefresh: _loadChildData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              // Top bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.brown),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    tooltip: 'Back',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.brown),
                                    onPressed: _loadChildData,
                                    tooltip: 'Refresh',
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
                                            CircleAvatar(
                                              radius: 50,
                                              backgroundColor: Colors.brown.withOpacity(0.1),
                                              child: const Icon(Icons.person, size: 60, color: Colors.brown),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "${_childName.toUpperCase()}'S PROFILE",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontFamily: 'SpecialElite',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 24,
                                                color: Colors.black87,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Character list
                              Transform.rotate(
                                angle: 1 * 3.1416 / 180,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
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
                                        child: _characters.isEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.all(24.0),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.emoji_emotions_outlined,
                                                        size: 48, color: Colors.grey[400]),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No character data available yet.',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'SpecialElite',
                                                        color: Colors.grey[700],
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Start logging feelings to see progress!',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'SpecialElite',
                                                        color: Colors.grey[500],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "CHARACTERS",
                                                        style: TextStyle(
                                                          fontFamily: 'SpecialElite',
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 18,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.download, color: Colors.brown),
                                                        onPressed: _showExportDialog,
                                                        tooltip: 'Export to CSV',
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  for (int i = 0; i < _characters.length; i++) ...[
                                                    CharacterRow(c: _characters[i]),
                                                    if (i != _characters.length - 1)
                                                      const SizedBox(height: 12),
                                                  ],
                                                ],
                                              ),
                                      ),
                                    ],
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