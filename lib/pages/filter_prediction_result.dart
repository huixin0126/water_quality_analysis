import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_model.dart';
import '../main.dart';
import '../class/reminder.dart';
import '../pages/add_reminder_page.dart';

class FilterPredictionResultPage extends StatelessWidget {
  final Map<String, dynamic> predictionData;
  const FilterPredictionResultPage({
    Key? key,
    required this.predictionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (predictionData == null) {
      // Complete the try-catch block
    return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text('Error: Prediction data is null'),
        ),
      );
    }
    
    try {
      final FilterModel filterData = FilterModel.fromJson(predictionData);
      // Format dates for display
      final installDate = DateTime.parse(filterData.installationDate);
      final replacementDate = DateTime.parse(filterData.replacementDate);
      final dateFormat = DateFormat('MMM d, yyyy');
    
    // Calculate health status
    String healthStatus;
    Color healthColor;
    if (filterData.healthPercentage > 70) {
      healthStatus = 'Healthy';
      healthColor = Colors.green;
    } else if (filterData.healthPercentage > 30) {
      healthStatus = 'Fair';
      healthColor = Colors.orange;
    } else {
      healthStatus = 'Poor';
      healthColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Health Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Health',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${filterData.healthPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: healthColor,
                                ),
                              ),
                              Text(
                                healthStatus,
                                style: TextStyle(
                                  color: healthColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: filterData.healthPercentage / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: filterData.healthPercentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Usage Statistics Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usage Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Installation Date', dateFormat.format(installDate)),
                      _buildInfoRow('Days in Use', '${filterData.daysInUse} days'),
                      _buildInfoRow('Hours Used', '${filterData.hoursUsed.toStringAsFixed(1)} hours'),
                      _buildInfoRow('Daily Usage', '${filterData.dailyUsageHours.toStringAsFixed(1)} hours/day'),
                      _buildInfoRow('Predicted Life', '${filterData.predictedLifeHours.toStringAsFixed(1)} hours'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Water Quality Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Water Quality Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQualityMeter('Efficiency', filterData.currentEfficiency, filterData.initialEfficiency),
                      const SizedBox(height: 8),
                      _buildQualityMeter('TDS Level', filterData.tds, 500.0, lowerIsBetter: true),
                      const SizedBox(height: 8),
                      _buildQualityMeter('Turbidity', filterData.turbidity, 10.0, lowerIsBetter: true),
                      const SizedBox(height: 8),
                      _buildQualityMeter('pH Level', filterData.ph, 7.0, isPhScale: true),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Replacement Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Replacement Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Estimated Replacement Date', dateFormat.format(replacementDate)),
                      _buildInfoRow('Days Until Replacement', '${filterData.daysUntilReplacement} days'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/filter_search');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Order Replacement Filter',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Debug logging
                            print('Schedule Maintenance button pressed');
                            print('Replacement date from filter data: ${filterData.replacementDate}');
                            print('Parsed replacement date: ${replacementDate.toString()}');
                            print('Current time: ${DateTime.now().toString()}');
                            print('Is replacement date in future: ${replacementDate.isAfter(DateTime.now())}');
                            
                            // Navigate to add reminder page with filter replacement details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddReminderPage(
                                  reminder: Reminder(
                                    title: 'Filter Replacement',
                                    dateTime: replacementDate,
                                    repeatDays: [],
                                    notes: 'Filter replacement due based on analysis. Estimated replacement date: ${dateFormat.format(replacementDate)}',
                                    type: 'Filter Replacement',
                                  ),
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Schedule Maintenance',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tips and Recommendations
              const Text(
                'Tips & Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTipCard(
                icon: Icons.opacity,
                title: 'Improve Water Quality',
                description: 'Consider pre-filtering water if TDS levels are high to extend filter life.',
              ),
              _buildTipCard(
                icon: Icons.timer,
                title: 'Optimal Usage',
                description: 'Run water for 10 seconds before collecting filtered water for best results.',
              ),
              _buildTipCard(
                icon: Icons.calendar_today,
                title: 'Regular Maintenance',
                description: 'Schedule a reminder for your next filter change to ensure optimal performance.',
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      print('Error parsing filter data: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Processing Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Details: $e',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build quality meters
  Widget _buildQualityMeter(String label, double value, double maxValue, {bool lowerIsBetter = false, bool isPhScale = false}) {
    double percentage;
    Color meterColor;
    
    if (isPhScale) {
      // pH Scale: optimal is 7.0, scale from 0-14
      percentage = 1.0 - (((value - 7.0).abs()) / 7.0);
      if (value >= 6.5 && value <= 8.5) {
        meterColor = Colors.green;
      } else if (value >= 6.0 && value <= 9.0) {
        meterColor = Colors.orange;
      } else {
        meterColor = Colors.red;
      }
    } else if (lowerIsBetter) {
      // Lower is better (like TDS)
      percentage = 1.0 - (value / maxValue);
      if (percentage > 0.7) {
        meterColor = Colors.green;
      } else if (percentage > 0.3) {
        meterColor = Colors.orange;
      } else {
        meterColor = Colors.red;
      }
    } else {
      // Higher is better (like efficiency)
      percentage = value / maxValue;
      if (percentage > 0.7) {
        meterColor = Colors.green;
      } else if (percentage > 0.3) {
        meterColor = Colors.orange;
      } else {
        meterColor = Colors.red;
      }
    }
    
    // Clamp percentage between 0 and 1
    percentage = percentage.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              isPhScale ? value.toStringAsFixed(1) : '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: meterColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(meterColor),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  // Helper method to build tip cards
  Widget _buildTipCard({required IconData icon, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
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
}