import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/child_data_service.dart';
import '../services/avatar_storage_service.dart';
import '../features/character.dart';
import '../widgets/char_row.dart';

// Conditional imports for web vs mobile
import 'csv_export_stub.dart'
    if (dart.library.html) 'csv_export_web.dart'
    if (dart.library.io) 'csv_export_mobile.dart' as csv_export;

enum TimeFilter { week, month, year, all }
enum ViewMode { list, chart }

class ParentViewChildPage extends StatefulWidget {
  final String childId;
  final String childName;

  const ParentViewChildPage({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ParentViewChildPage> createState() => _ParentViewChildPageState();
}

class _ParentViewChildPageState extends State<ParentViewChildPage> {
  String _childName = '';
  List<Character> _allCharacters = [];
  List<Character> _filteredCharacters = [];
  List<Map<String, dynamic>> _rawLogs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _avatarSvg;
  
  TimeFilter _timeFilter = TimeFilter.month;
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    _childName = widget.childName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadChildData();
      }
    });
  }

  DateTime _getFilterStartDate() {
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.week:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.month:
        return now.subtract(const Duration(days: 30));
      case TimeFilter.year:
        return now.subtract(const Duration(days: 365));
      case TimeFilter.all:
        return DateTime(2000); // Far past date
    }
  }

  void _applyTimeFilter() {
    final startDate = _getFilterStartDate();
    setState(() {
      _filteredCharacters = _allCharacters.where((c) {
        return c.date.isAfter(startDate);
      }).toList();
    });
  }

  Future<void> _loadChildData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final childProfile = await ChildDataService.getChildProfile(widget.childId, context);
      if (!mounted) return;
      final childLogs = await ChildDataService.getChildLogs(widget.childId, context);
      if (!mounted) return;
      final characterLibrary = await ChildDataService.getCharacterLibrary(context);

      if (childProfile != null) {
        setState(() {
          _childName = childProfile['name'] ?? widget.childName;
        });
      }

      _rawLogs = childLogs;

      final logEntries = ChildDataService.processLogsToIndividualEntries(childLogs, characterLibrary);
      
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
          averageLevel: level,
        );
      }).toList();

      final avatarSvg = await AvatarStorageService.getAvatarSvg(widget.childId);

      setState(() {
        _allCharacters = characters;
        _avatarSvg = avatarSvg;
        _isLoading = false;
      });
      
      _applyTimeFilter();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Get data for trend line chart (average level over time)
  List<FlSpot> _getTrendData() {
    if (_filteredCharacters.isEmpty) return [];
    
    final startDate = _getFilterStartDate();
    final now = DateTime.now();
    
    // Group by day and calculate daily averages
    final Map<int, List<int>> dailyLevels = {};
    
    for (final char in _filteredCharacters) {
      final daysDiff = now.difference(char.date).inDays;
      dailyLevels.putIfAbsent(daysDiff, () => []).add(char.averageLevel);
    }
    
    // Create spots for the chart
    final spots = <FlSpot>[];
    final maxDays = _timeFilter == TimeFilter.week ? 7 : 
                    _timeFilter == TimeFilter.month ? 30 : 
                    _timeFilter == TimeFilter.year ? 365 : 90;
    
    for (int i = maxDays; i >= 0; i--) {
      if (dailyLevels.containsKey(i)) {
        final levels = dailyLevels[i]!;
        final avg = levels.reduce((a, b) => a + b) / levels.length;
        spots.add(FlSpot((maxDays - i).toDouble(), avg));
      }
    }
    
    // Sort by x value
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    return spots;
  }

  // Get data for character frequency pie chart
  Map<String, int> _getCharacterFrequency() {
    final frequency = <String, int>{};
    for (final char in _filteredCharacters) {
      frequency[char.name] = (frequency[char.name] ?? 0) + 1;
    }
    return frequency;
  }

  // Get daily frequency data for bar chart
  Map<int, int> _getDailyFrequency() {
    final now = DateTime.now();
    final frequency = <int, int>{};
    
    for (final char in _filteredCharacters) {
      final dayOfWeek = char.date.weekday; // 1 = Monday, 7 = Sunday
      frequency[dayOfWeek] = (frequency[dayOfWeek] ?? 0) + 1;
    }
    
    return frequency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/corkboard.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.brown.withOpacity(0.1)),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          children: [
            _buildTopBar(),
            const SizedBox(height: 20),
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildFilterAndToggle(),
            const SizedBox(height: 16),
            _viewMode == ViewMode.chart
                ? _buildChartView()
                : _buildListView(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
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
                                    icon: const Icon(Icons.arrow_back, color: Color(0xff2275d3), size: 24),
                                    onPressed: () => Navigator.of(context).pop(),
                                    tooltip: 'Back',
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xff2275d3)),
                                      ),
              child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye, size: 16, color: Color(0xff2275d3)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Parent View',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff2275d3),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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
                                      child: IconButton(
                                        icon: const Icon(Icons.download, color: Colors.brown),
                                        onPressed: _exportToCsv,
                                        tooltip: 'Export to CSV',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
    );
  }
                            
  Widget _buildProfileCard() {
    return Transform.rotate(
                              angle: -2 * 3.1416 / 180,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8DC),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
            BoxShadow(offset: Offset(3, 3), blurRadius: 5, color: Colors.black26),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                                    ),
                                    Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        _ChildAvatar(svgData: _avatarSvg, size: 50),
                                        const SizedBox(height: 16),
                                        Text(
                                          _childName.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'SpecialElite',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 32,
                                            color: Colors.black87,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xff2275d3),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                      Icon(Icons.verified_user, color: Colors.white, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'DETECTIVE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
    );
  }

  Widget _buildStatsRow() {
    final avgLevel = _filteredCharacters.isEmpty
        ? 0.0
        : _filteredCharacters.map((c) => c.averageLevel).reduce((a, b) => a + b) / _filteredCharacters.length;
    
    return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _PinnedStatsNote(
            number: _filteredCharacters.length,
            label: 'Logs',
                                    rotation: 1.5,
                                  ),
                                ),
        const SizedBox(width: 12),
                                Expanded(
                                  child: _PinnedStatsNote(
            number: avgLevel.round(),
            label: 'Avg Level',
            rotation: -1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PinnedStatsNote(
            number: _getCharacterFrequency().length,
            label: 'Characters',
            rotation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black26),
        ],
      ),
      child: Column(
        children: [
          // Time Filter Dropdown
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xff2275d3)),
              const SizedBox(width: 8),
              const Text(
                'Time Period:',
                style: TextStyle(fontFamily: 'SpecialElite', fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff2275d3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TimeFilter>(
                      value: _timeFilter,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: TimeFilter.week, child: Text('Past Week')),
                        DropdownMenuItem(value: TimeFilter.month, child: Text('Past Month')),
                        DropdownMenuItem(value: TimeFilter.year, child: Text('Past Year')),
                        DropdownMenuItem(value: TimeFilter.all, child: Text('All Time')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _timeFilter = value);
                          _applyTimeFilter();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // View Mode Toggle
          Row(
            children: [
              const Icon(Icons.view_module, color: Color(0xff2275d3)),
              const SizedBox(width: 8),
              const Text(
                'View:',
                style: TextStyle(fontFamily: 'SpecialElite', fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _viewMode = ViewMode.list),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _viewMode == ViewMode.list
                                  ? const Color(0xff2275d3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.list,
                                  size: 18,
                                  color: _viewMode == ViewMode.list ? Colors.white : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'List',
                                  style: TextStyle(
                                    color: _viewMode == ViewMode.list ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _viewMode = ViewMode.chart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _viewMode == ViewMode.chart
                                  ? const Color(0xff2275d3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  size: 18,
                                  color: _viewMode == ViewMode.chart ? Colors.white : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Charts',
                                  style: TextStyle(
                                    color: _viewMode == ViewMode.chart ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartView() {
    if (_filteredCharacters.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Trend Line Chart
        _buildChartCard(
          title: 'FEELING LEVEL TREND',
          icon: Icons.trending_up,
          child: SizedBox(
            height: 200,
            child: _buildTrendChart(),
          ),
        ),
        const SizedBox(height: 16),
        // Character Frequency Pie Chart
        _buildChartCard(
          title: 'CHARACTER FREQUENCY',
          icon: Icons.pie_chart,
          child: SizedBox(
            height: 200,
            child: _buildPieChart(),
          ),
        ),
        const SizedBox(height: 16),
        // Daily Activity Bar Chart
        _buildChartCard(
          title: 'ACTIVITY BY DAY',
          icon: Icons.bar_chart,
          child: SizedBox(
            height: 200,
            child: _buildBarChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(offset: Offset(3, 3), blurRadius: 5, color: Colors.black26),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff2275d3), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SpecialElite',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final spots = _getTrendData();
    if (spots.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xff2275d3),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xff2275d3),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xff2275d3).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final frequency = _getCharacterFrequency();
    if (frequency.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final colors = [
      const Color(0xffe67268),
      const Color(0xff4a90e2),
      const Color(0xff7cb342),
      const Color(0xffffa726),
      const Color(0xffab47bc),
      const Color(0xff26c6da),
      const Color(0xffef5350),
      const Color(0xff66bb6a),
    ];

    final total = frequency.values.reduce((a, b) => a + b);
    int colorIndex = 0;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: frequency.entries.map((entry) {
                final color = colors[colorIndex % colors.length];
                colorIndex++;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${((entry.value / total) * 100).round()}%',
                  color: color,
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: frequency.entries.take(5).map((entry) {
              final color = colors[frequency.keys.toList().indexOf(entry.key) % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry.key.split(' ').first,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final dailyFreq = _getDailyFrequency();
    if (dailyFreq.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxValue = dailyFreq.values.isEmpty ? 1 : dailyFreq.values.reduce(math.max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() + 2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        barGroups: List.generate(7, (index) {
          final dayNum = index + 1; // 1 = Monday
          final count = dailyFreq[dayNum] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: const Color(0xff2275d3),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredCharacters.isEmpty) {
      return _buildEmptyState();
    }

    return Transform.rotate(
                                angle: 1 * 3.1416 / 180,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
            BoxShadow(offset: Offset(3, 3), blurRadius: 5, color: Colors.black26),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                    'FEELING LOG',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                  for (int i = 0; i < _filteredCharacters.length && i < 20; i++) ...[
                    CharacterRow(c: _filteredCharacters[i]),
                    if (i != math.min(_filteredCharacters.length - 1, 19))
                                                const SizedBox(height: 12),
                                            ],
                  if (_filteredCharacters.length > 20)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          '+ ${_filteredCharacters.length - 20} more entries',
                          style: TextStyle(
                            fontFamily: 'SpecialElite',
                            color: Colors.grey[600],
                          ),
                        ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Transform.rotate(
                                angle: -0.5 * 3.1416 / 180,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
            BoxShadow(offset: Offset(3, 3), blurRadius: 5, color: Colors.black26),
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
                                        child: Column(
                                          children: [
                  Icon(Icons.emoji_emotions_outlined, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                    'No data for this period',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                color: Colors.grey[700],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                    'Try selecting a different time range',
                                              style: TextStyle(
                                                fontFamily: 'SpecialElite',
                                                color: Colors.grey[500],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
      ),
    );
  }

  int _calculateTotalStars() {
    return _filteredCharacters.fold(0, (sum, character) => sum + character.averageLevel);
  }

  Future<void> _exportToCsv() async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final childLogs = await ChildDataService.getChildLogs(widget.childId, context);

      if (childLogs.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logs found for this child')),
        );
        return;
      }

      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Log ID,Character Name,Level,Timestamp');
      
      for (final log in childLogs) {
        final logId = log['id'] ?? '';
        final charName = log['characterName'] ?? '';
        final level = log['level'] ?? '';
        final timestamp = log['timestamp'] ?? '';
        
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

      if (!mounted) return;
      Navigator.of(context).pop();

      // Use platform-specific export
      await csv_export.downloadCsv(csvContent, fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb 
            ? 'CSV downloaded!' 
            : 'CSV exported successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }
}

class _PinnedStatsNote extends StatelessWidget {
  final int number;
  final String label;
  final double rotation;

  const _PinnedStatsNote({
    required this.number,
    required this.label,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1416 / 180,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E68C),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(offset: Offset(3, 3), blurRadius: 5, color: Colors.black26),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 4,
              left: 8,
              child: Icon(Icons.push_pin, color: Colors.redAccent, size: 16),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Text(
                    number.toString(),
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'SpecialElite',
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
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
  final double size;
  const _ChildAvatar({required this.svgData, this.size = 32});

  @override
  Widget build(BuildContext context) {
    if (svgData == null || svgData!.isEmpty) {
      return CircleAvatar(
        radius: size,
        backgroundColor: const Color(0xff4a90e2).withOpacity(0.1),
        child: Icon(Icons.child_care, size: size, color: const Color(0xff4a90e2)),
      );
    }

    return Container(
      width: size * 2,
      height: size * 2,
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
              return Icon(Icons.child_care, size: size, color: const Color(0xff4a90e2));
            }
          },
        ),
      ),
    );
  }
}
