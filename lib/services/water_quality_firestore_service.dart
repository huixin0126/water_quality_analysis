import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaterQualityFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define the water quality parameters and their ranges
  static const Map<String, Map<String, dynamic>> waterQualityParameters = {
    'ph': {'name': 'pH', 'min': 0, 'max': 14},
    'hardness': {'name': 'Hardness', 'min': 0, 'max': 1000},
    'solids': {'name': 'TDS', 'min': 0, 'max': 100000},
    'chloramines': {'name': 'Chloramines', 'min': 0, 'max': 15},
    'sulfate': {'name': 'Sulfate', 'min': 0, 'max': 1000},
    'conductivity': {'name': 'Conductivity', 'min': 0, 'max': 2000},
    'organic_carbon': {'name': 'Organic Carbon', 'min': 0, 'max': 50},
    'trihalomethanes': {'name': 'Trihalomethanes', 'min': 0, 'max': 200},
    'turbidity': {'name': 'Turbidity', 'min': 0, 'max': 10},
  };

  Future<List<Map<String, dynamic>>> getWaterQualityData(String timeRange) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Calculate the start date based on the selected time range
      DateTime startDate;
      final now = DateTime.now();
      
      switch (timeRange) {
        case 'Last 7 days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Last 90 days':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      // Query the water analysis results
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_analysis')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .orderBy('timestamp', descending: false)
          .get();

      // Convert the documents to a list of maps
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'timestamp': data['timestamp'],
          'ph': data['ph'] ?? 0.0,
          'hardness': data['hardness'] ?? 0.0,
          'solids': data['solids'] ?? 0.0, // TDS
          'chloramines': data['chloramines'] ?? 0.0,
          'sulfate': data['sulfate'] ?? 0.0,
          'conductivity': data['conductivity'] ?? 0.0,
          'organic_carbon': data['organic_carbon'] ?? 0.0,
          'trihalomethanes': data['trihalomethanes'] ?? 0.0,
          'turbidity': data['turbidity'] ?? 0.0,
          'potable_probability': data['potable_probability'] ?? 0.0,
          'not_potable_probability': data['not_potable_probability'] ?? 0.0,
          'is_potable': data['is_potable'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('Error fetching water quality data: $e');
      rethrow;
    }
  }

  List<FlSpot> convertToChartData(List<Map<String, dynamic>> data, String parameter) {
    if (parameter == 'analysis_percentage') {
      return data.asMap().entries.map((entry) {
        final index = entry.key.toDouble();
        final value = entry.value['potable_probability'] as double? ?? 0.0;
        return FlSpot(index, value);
      }).toList();
    }
    return [];
  }

  List<String> getDateLabels(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final timestamp = item['timestamp'];
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.month}/${date.day}';
      }
      return '';
    }).toList();
  }

  // Get the status color for a parameter value
  Color getParameterStatusColor(String parameter, double value) {
    final paramInfo = waterQualityParameters[parameter];
    if (paramInfo == null) return Colors.grey;

    final maxValue = paramInfo['max'] as double;
    final percentage = value / maxValue;

    if (parameter == 'ph') {
      // Special case for pH: optimal range is 6.5-8.5
      if (value >= 6.5 && value <= 8.5) return Colors.green;
      if (value >= 6.0 && value <= 9.0) return Colors.orange;
      return Colors.red;
    } else if (parameter == 'solids') {
      // Special case for TDS (solids)
      if (value <= 300) return Colors.green;
      if (value <= 600) return Colors.orange;
      return Colors.red;
    } else {
      // For other parameters, lower is generally better
      if (percentage <= 0.3) return Colors.green;
      if (percentage <= 0.7) return Colors.orange;
      return Colors.red;
    }
  }

  // Get the status text for a parameter value
  String getParameterStatusText(String parameter, double value) {
    final paramInfo = waterQualityParameters[parameter];
    if (paramInfo == null) return 'Unknown';

    final maxValue = paramInfo['max'] as double;
    final percentage = value / maxValue;

    if (parameter == 'ph') {
      if (value >= 6.5 && value <= 8.5) return 'Optimal';
      if (value >= 6.0 && value <= 9.0) return 'Acceptable';
      return 'Poor';
    } else if (parameter == 'solids') {
      if (value <= 300) return 'Excellent';
      if (value <= 600) return 'Acceptable';
      return 'Poor';
    } else {
      if (percentage <= 0.3) return 'Good';
      if (percentage <= 0.7) return 'Fair';
      return 'Poor';
    }
  }
} 