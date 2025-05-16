import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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