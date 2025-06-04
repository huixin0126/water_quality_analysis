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
  Map<String, dynamic>? _latestTurbidityData;
  Map<String, dynamic>? _latestFilterPrediction;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadWaterQualityData();
    _loadLatestTurbidityData();
    _loadLatestFilterPrediction();
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
      setState(() {
        _waterQualityData = data;
        _dateLabels = _waterQualityService.getDateLabels(data);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load water quality data: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  // Load latest turbidity data
  Future<void> _loadLatestTurbidityData() async {
    try {
      final data = await _turbidityService.getLatestTurbidityData();
      setState(() {
        _latestTurbidityData = data;
      });
    } catch (e) {
      print('Error loading turbidity data: $e');
    }
  }

  Future<void> _loadLatestFilterPrediction() async {
    try {
      final prediction = await _filterPredictionService.getLatestPrediction();
      setState(() {
        _latestFilterPrediction = prediction;
      });
    } catch (e) {
      print('Error loading filter prediction: $e');
    }
  }

  // Get chart data for a specific parameter
  List<FlSpot> _getChartData(String parameter) {
    return _waterQualityService.convertToChartData(_waterQualityData, parameter);
  }

  // Calculate overall water quality score
  double _calculateWaterQualityScore() {
    if (_waterQualityData.isEmpty) return 0.0;
    
    final latestData = _waterQualityData.last;
    double ph = latestData['ph'] ?? 7.0;
    double tds = latestData['tds'] ?? 0.0;
    
    // pH score (optimal range: 6.5-8.5)
    double phScore = 0.0;
    if (ph >= 6.5 && ph <= 8.5) {
      phScore = 100.0;
    } else if (ph >= 6.0 && ph <= 9.0) {
      phScore = 70.0;
    } else {
      phScore = 30.0;
    }
    
    // TDS score (lower is better)
    double tdsScore = 0.0;
    if (tds < 300) {
      tdsScore = 100.0;
    } else if (tds < 600) {
      tdsScore = 70.0;
    } else if (tds < 900) {
      tdsScore = 40.0;
    } else {
      tdsScore = 20.0;
    }
    
    // Calculate weighted average
    return (phScore * 0.4 + tdsScore * 0.6);
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
                      mainAxisAlignment: MainAxisAlignment.start,
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
                            const Text('TDS', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 16),
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
                            const Text('PH', style: TextStyle(fontSize: 12)),
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
                                      'Swipe to switch between TDS and pH',
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
                                // TDS Chart
                                Column(
                                  children: [
                                    const Text(
                                      'TDS (ppm)',
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
                                                    'TDS: $value ppm\n$date',
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
                                            horizontalInterval: 200,
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
                                                    '${value.toInt()}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  );
                                                },
                                                interval: 200,
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
                                          maxY: 1000,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _getChartData('tds'),
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
                                
                                // pH Chart
                                Column(
                                  children: [
                                    const Text(
                                      'pH Level',
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
                                                    'pH: $value\n$date',
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
                                            horizontalInterval: 1,
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
                                                    value.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFFEC4899),
                                                    ),
                                                  );
                                                },
                                                interval: 1,
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
                                          maxY: 14,
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: _getChartData('ph'),
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
                      // PH Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFFEF2F2),
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
                                  Icons.water_drop,
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
                                      'PH',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFEC4899),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _waterQualityData.last['ph'].toString(),
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
                      
                      // TDS Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFF0F0FF),
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
                                  Icons.water,
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
                                      'TDS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_waterQualityData.last['tds']} ppm',
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
                      
                      // Turbidity Card
                      if (_latestTurbidityData != null)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color(0xFFE0F2FE),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.opacity,
                                    color: Color(0xFF0EA5E9),
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
                                          color: Color(0xFF0EA5E9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _latestTurbidityData!['confidence_display'],
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
                      if (_latestTurbidityData != null)
                        const SizedBox(height: 8),
                      
                      // Filter Replacement Card
                      if (_latestFilterPrediction != null)
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
                                        'Filter Replacement',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_filterPredictionService.formatDate(_latestFilterPrediction!['replacementDate'])} (${_latestFilterPrediction!['daysUntilReplacement']} days)',
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
                    ],
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Overall Water Quality Card (Moved to bottom)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Water Quality',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          'No water quality data available',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: _calculateWaterQualityScore() / 100,
                                strokeWidth: 20,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _calculateWaterQualityScore() >= 70
                                      ? const Color(0xFF10B981)
                                      : _calculateWaterQualityScore() >= 40
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_calculateWaterQualityScore().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _calculateWaterQualityScore() >= 70
                                        ? const Color(0xFF10B981)
                                        : _calculateWaterQualityScore() >= 40
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444),
                                  ),
                                ),
                                Text(
                                  _calculateWaterQualityScore() >= 70
                                      ? 'Good'
                                      : _calculateWaterQualityScore() >= 40
                                          ? 'Fair'
                                          : 'Poor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _calculateWaterQualityScore() >= 70
                                        ? const Color(0xFF10B981)
                                        : _calculateWaterQualityScore() >= 40
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}