import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days'];

  // Sample data for the chart
  final List<FlSpot> tdsSpots = [
    FlSpot(0, 15),
    FlSpot(1, 18),
    FlSpot(2, 22),
    FlSpot(3, 26),
    FlSpot(4, 24),
    FlSpot(5, 20),
    FlSpot(6, 17),
  ];

  final List<FlSpot> phSpots = [
    FlSpot(0, 5),
    FlSpot(1, 4.5),
    FlSpot(2, 5.2),
    FlSpot(3, 6.3),
    FlSpot(4, 7.4),
    FlSpot(5, 8.1),
    FlSpot(6, 9),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Quality Card
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
                    // Header with dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Water Quality',
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
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (LineBarSpot spot) => Colors.white.withOpacity(0.8),
                              tooltipBorderRadius: BorderRadius.circular(8),
                              tooltipBorder: BorderSide(color: Colors.grey, width: 1),
                              tooltipPadding: EdgeInsets.all(8),
                              tooltipMargin: 10,
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
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
                                getTitlesWidget: (value, meta) {
                                  final days = ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'];
                                  if (value >= 0 && value < days.length) {
                                    return Text(
                                      days[value.toInt()],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // TDS Line
                            LineChartBarData(
                              spots: tdsSpots,
                              isCurved: true,
                              color: const Color(0xFF6366F1),
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                              ),
                            ),
                            // PH Line
                            LineChartBarData(
                              spots: phSpots,
                              isCurved: true,
                              color: const Color(0xFFEC4899),
                              barWidth: 3,
                              dotData: FlDotData(show: false),
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
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Values Row
            Row(
              children: [
                // Recent PH Card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent PH',
                            style: TextStyle(
                              color: Color(0xFFEC4899),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '6',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('ph'),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFFEC4899),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/water_analysis');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Recent TDS Card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFE0E7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent TDS',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '23',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('ppm'),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF6366F1),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/water_analysis');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bottom Cards Row
            Row(
              children: [
                // Filter Replacement Card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFE0E7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Replacement',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimate Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '22/09/2025',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF6366F1),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/filter_prediction');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Reminder Card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFDCFCE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reminder',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1 Cup of Water',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '8:00 AM',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF10B981),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/water_intake_reminder');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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