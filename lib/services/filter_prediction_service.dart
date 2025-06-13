import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class FilterPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getLatestPrediction() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('filter_prediction')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return {
        'id': snapshot.docs.first.id,
        ...data,
      };
    } catch (e) {
      print('Error fetching latest prediction: $e');
      return null;
    }
  }

  // Get filter prediction data for a specific time range
  Future<List<Map<String, dynamic>>> getPredictionData(String timeRange) async {
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

      // Query the filter prediction results
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('filter_prediction')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .orderBy('timestamp', descending: false)
          .get();

      // Convert the documents to a list of maps
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'timestamp': data['timestamp'],
          'healthPercentage': data['healthPercentage'] ?? 0.0,
          'currentEfficiency': data['currentEfficiency'] ?? 0.0,
          'replacementDate': data['replacementDate'],
          'daysUntilReplacement': data['daysUntilReplacement'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching filter prediction data: $e');
      rethrow;
    }
  }

  // Convert filter prediction data to chart data points
  List<FlSpot> convertToChartData(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value['healthPercentage'] as double? ?? 0.0;
      return FlSpot(index, value);
    }).toList();
  }

  Future<void> deletePrediction(String predictionId) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('filter_prediction')
          .doc(predictionId)
          .delete();
    } catch (e) {
      print('Error deleting prediction: $e');
      rethrow;
    }
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return 'Invalid date';
    }
    
    return DateFormat('MMM d, yyyy').format(date);
  }
} 