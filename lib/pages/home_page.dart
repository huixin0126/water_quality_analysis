import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/water_quality_firestore_service.dart';
import '../services/water_turbidity_service.dart';
import '../services/filter_prediction_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days'];
  String? _profileImageUrl;
  bool _isLoadingProfileImage = true;
  bool _isLoadingData = true;
  String? _errorMessage;

  final WaterQualityFirestoreService _waterQualityService = WaterQualityFirestoreService();
  final WaterTurbidityService _turbidityService = WaterTurbidityService();
  final FilterPredictionService _filterPredictionService = FilterPredictionService();
  List<Map<String, dynamic>> _waterQualityData = [];
  List<String> _dateLabels = [];
  List<Map<String, dynamic>> _turbidityData = [];
  List<Map<String, dynamic>> _filterPredictionData = [];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadWaterQualityData();
  }

  // Load profile image from Firestore
  Future<void> _loadProfileImage() async {
    setState(() {
      _isLoadingProfileImage = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // First check if user has a photoURL directly in Firebase Auth
        if (currentUser.photoURL != null) {
          setState(() {
            _profileImageUrl = currentUser.photoURL;
          });
        } else {
          // If not, try to fetch from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              _profileImageUrl = userData['profileImageUrl'];
            });
          }
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoadingProfileImage = false;
      });
    }
  }

  // Load water quality data from Firestore
  Future<void> _loadWaterQualityData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final data = await _waterQualityService.getWaterQualityData(_selectedTimeRange);
      final turbidityData = await _turbidityService.getTurbidityData(_selectedTimeRange);
      final filterData = await _filterPredictionService.getPredictionData(_selectedTimeRange);
      
      // Process water quality data to get analysis percentage
      final processedWaterQualityData = data.map((item) {
        final potableProbability = item['potable_probability'] as double? ?? 0.0;
        return {
          ...item,
          'analysis_percentage': potableProbability.round(),
        };
      }).toList();

      // Process turbidity data to get percentage from confidence display
      final processedTurbidityData = turbidityData.map((item) {
        final confidenceDisplay = item['confidence_display'] as String? ?? '0%';
        // Keep the entire confidence display string
        return {
          ...item,
          'turbidity_percentage': confidenceDisplay,
        };
      }).toList();
      
      setState(() {
        _waterQualityData = processedWaterQualityData;
        _turbidityData = processedTurbidityData;
        _filterPredictionData = filterData;
        _dateLabels = _waterQualityService.getDateLabels(data);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  // Get chart data for a specific parameter
  List<FlSpot> _getChartData(String parameter) {
    switch (parameter) {
      case 'analysis':
        return _waterQualityService.convertToChartData(_waterQualityData, 'analysis_percentage');
      case 'turbidity':
        return _turbidityService.convertToChartData(_turbidityData);
      case 'filter':
        return _filterPredictionService.convertToChartData(_filterPredictionData);
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile').then((_) {
                  // Reload profile image when returning from profile page
                  _loadProfileImage();
                });
              },
              child: _isLoadingProfileImage
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                            )
                          : null,
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Quality Trends Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Water Quality Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedTimeRange,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedTimeRange = newValue;
                              });
                              _loadWaterQualityData();
                            }
                          },
                          items: _timeRanges.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          underline: Container(),
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Chart Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Analysis %', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Turbidity %', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Filter %', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Line Chart
                    if (_isLoadingData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_waterQualityData.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No water quality data available for the selected time range',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Graph Type Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.swap_horiz, size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Swipe to switch between graphs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Graphs with PageView
                          SizedBox(
                            height: 280,
                            child: PageView(
                              children: [
                                // Analysis Percentage Chart
                                Column(
                                  children: [
                                    const Text(
                                      'Water Analysis Percentage',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: LineChart(
                                        LineChartData(
                                          lineTouchData: LineTouchData(
                                            touchTooltipData: LineTouchTooltipData(
                                              getTooltipColor: (LineBarSpot spot) => Colors.white.withOpacity(0.8),
                                              tooltipBorderRadius: BorderRadius.circular(8),
                                              tooltipBorder: BorderSide(color: Colors.grey, width: 1),
                                              tooltipPadding: const EdgeInsets.all(8),
                                              tooltipMargin: 10,
                                              getTooltipItems: (List<LineBarSpot> spots) {
                                                return spots.map((spot) {
                                                  final date = _dateLabels[spot.x.toInt()];
                                                  final value = spot.y.toStringAsFixed(1);
                                                  return LineTooltipItem(
                                                    'Analysis: $value%\n$date',
                                                    const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                            ),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: 20,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(
                                                color: Colors.grey.withOpacity(0.2),
                                                strokeWidth: 1,
                                              );
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                getTitlesWidget: (value, meta) {
                                                  if (value >= 0 && value < _dateLabels.length) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        _dateLabels[value.toInt()],
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const Text('');
                                                },
                                                interval: (_dateLabels.length / 5).ceil().toDouble(),
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 40,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  );
                                                },
                                                interval: 20,
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          minX: 0,
                                          maxX: (_dateLabels.length - 1).toDouble(),
                                          minY: 0,
                                          maxY: 100,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _getChartData('analysis'),
                                              isCurved: true,
                                              color: const Color(0xFF6366F1),
                                              barWidth: 2,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent, barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: 4,
                                                    color: const Color(0xFF6366F1),
                                                    strokeWidth: 1,
                                                    strokeColor: Colors.white,
                                                  );
                                                },
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Turbidity Chart
                                Column(
                                  children: [
                                    const Text(
                                      'Turbidity Percentage',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEC4899),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: LineChart(
                                        LineChartData(
                                          lineTouchData: LineTouchData(
                                            touchTooltipData: LineTouchTooltipData(
                                              getTooltipColor: (LineBarSpot spot) => Colors.white.withOpacity(0.8),
                                              tooltipBorderRadius: BorderRadius.circular(8),
                                              tooltipBorder: BorderSide(color: Colors.grey, width: 1),
                                              tooltipPadding: const EdgeInsets.all(8),
                                              tooltipMargin: 10,
                                              getTooltipItems: (List<LineBarSpot> spots) {
                                                return spots.map((spot) {
                                                  final date = _dateLabels[spot.x.toInt()];
                                                  final value = spot.y.toStringAsFixed(1);
                                                  return LineTooltipItem(
                                                    'Turbidity: $value%\n$date',
                                                    const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                            ),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: 20,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(
                                                color: Colors.grey.withOpacity(0.2),
                                                strokeWidth: 1,
                                              );
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                getTitlesWidget: (value, meta) {
                                                  if (value >= 0 && value < _dateLabels.length) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        _dateLabels[value.toInt()],
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const Text('');
                                                },
                                                interval: (_dateLabels.length / 5).ceil().toDouble(),
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 40,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFFEC4899),
                                                    ),
                                                  );
                                                },
                                                interval: 20,
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          minX: 0,
                                          maxX: (_dateLabels.length - 1).toDouble(),
                                          minY: 0,
                                          maxY: 100,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _getChartData('turbidity'),
                                              isCurved: true,
                                              color: const Color(0xFFEC4899),
                                              barWidth: 2,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent, barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: 4,
                                                    color: const Color(0xFFEC4899),
                                                    strokeWidth: 1,
                                                    strokeColor: Colors.white,
                                                  );
                                                },
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: const Color(0xFFEC4899).withOpacity(0.1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Filter Health Chart
                                Column(
                                  children: [
                                    const Text(
                                      'Filter Health Percentage',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: LineChart(
                                        LineChartData(
                                          lineTouchData: LineTouchData(
                                            touchTooltipData: LineTouchTooltipData(
                                              getTooltipColor: (LineBarSpot spot) => Colors.white.withOpacity(0.8),
                                              tooltipBorderRadius: BorderRadius.circular(8),
                                              tooltipBorder: BorderSide(color: Colors.grey, width: 1),
                                              tooltipPadding: const EdgeInsets.all(8),
                                              tooltipMargin: 10,
                                              getTooltipItems: (List<LineBarSpot> spots) {
                                                return spots.map((spot) {
                                                  final date = _dateLabels[spot.x.toInt()];
                                                  final value = spot.y.toStringAsFixed(1);
                                                  return LineTooltipItem(
                                                    'Filter Health: $value%\n$date',
                                                    const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                            ),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: 20,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(
                                                color: Colors.grey.withOpacity(0.2),
                                                strokeWidth: 1,
                                              );
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                getTitlesWidget: (value, meta) {
                                                  if (value >= 0 && value < _dateLabels.length) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        _dateLabels[value.toInt()],
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const Text('');
                                                },
                                                interval: (_dateLabels.length / 5).ceil().toDouble(),
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 40,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  );
                                                },
                                                interval: 20,
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          minX: 0,
                                          maxX: (_dateLabels.length - 1).toDouble(),
                                          minY: 0,
                                          maxY: 100,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _getChartData('filter'),
                                              isCurved: true,
                                              color: const Color(0xFF10B981),
                                              barWidth: 2,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent, barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: 4,
                                                    color: const Color(0xFF10B981),
                                                    strokeWidth: 1,
                                                    strokeColor: Colors.white,
                                                  );
                                                },
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: const Color(0xFF10B981).withOpacity(0.1),
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
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Analysis Cards
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoadingData)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_waterQualityData.isEmpty)
                  const Center(
                    child: Text(
                      'No recent water quality analysis available',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: [
                      // Water Quality Analysis Card
                      if (_waterQualityData.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                          color: const Color(0xFFEEF2FF),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                    color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        'Water Quality',
                                      style: TextStyle(
                                        fontSize: 13,
                                          color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${_waterQualityData.last['analysis_percentage']}%',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ],
                      
                      // Turbidity Card
                      if (_turbidityData.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                          color: const Color(0xFFFDF2F8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFFEC4899),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        'Turbidity',
                                      style: TextStyle(
                                        fontSize: 13,
                                          color: Color(0xFFEC4899),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${_turbidityData.last['turbidity_percentage']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ],
                      
                      // Filter Health Card
                      if (_filterPredictionData.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color(0xFFDCFCE7),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.filter_alt,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Filter Health',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_filterPredictionData.last['healthPercentage']}%',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      
                      // Filter Replacement Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color(0xFFDCFCE7),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Filter Replacement',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_filterPredictionData.last['daysUntilReplacement']} days left',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        const Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
                          color: Color(0xFFDCFCE7),
              child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No filter prediction data available',
                      style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF10B981),
                              ),
                          textAlign: TextAlign.center,
                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}