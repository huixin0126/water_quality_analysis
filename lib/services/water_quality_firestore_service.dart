import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterQualityFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          'tds': data['tds'] ?? 0.0,
          'ph': data['ph'] ?? 0.0,
          'turbidity': data['turbidity'] ?? 0.0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching water quality data: $e');
      rethrow;
    }
  }

  List<FlSpot> convertToChartData(List<Map<String, dynamic>> data, String parameter) {
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value[parameter] as double;
      return FlSpot(index, value);
    }).toList();
  }

  List<String> getDateLabels(List<Map<String, dynamic>> data) {
    return data.map((entry) {
      final timestamp = entry['timestamp'] as Timestamp;
      final date = timestamp.toDate();
      return '${date.day}/${date.month}';
    }).toList();
  }
} 