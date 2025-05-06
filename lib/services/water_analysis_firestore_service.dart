import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterAnalysisFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Save water analysis result to Firestore
  Future<String> saveWaterAnalysisResult({
    required double ph,
    required double tds,
    required double potableProbability,
    required bool isPotable,
    double? turbidity,
  }) async {
    try {
      // Check if user is logged in
      if (_userId == null) {
        throw Exception('User not logged in');
      }

      // Create a new document reference
      final docRef = _firestore.collection('users').doc(_userId).collection('water_analyses').doc();
      
      // Data to save
      final data = {
        'timestamp': FieldValue.serverTimestamp(),
        'ph': ph,
        'tds': tds,
        'potable_probability': potableProbability,
        'not_potable_probability': 100 - potableProbability,
        'is_potable': isPotable,
        'turbidity': turbidity,
      };

      // Save the data
      await docRef.set(data);
      
      // Return the document ID for reference
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save water analysis result: ${e.toString()}');
    }
  }

  // Get water analysis result by ID
  Future<Map<String, dynamic>> getWaterAnalysisResult(String analysisId) async {
    try {
      // Check if user is logged in
      if (_userId == null) {
        throw Exception('User not logged in');
      }

      // Get the document
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('water_analysis')
          .doc(analysisId)
          .get();

      // Check if document exists
      if (!docSnapshot.exists) {
        throw Exception('Analysis not found');
      }

      // Return the data
      return docSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get water analysis result: ${e.toString()}');
    }
  }

  // Get all water analysis results
  Future<List<Map<String, dynamic>>> getAllWaterAnalysisResults() async {
    try {
      // Check if user is logged in
      if (_userId == null) {
        throw Exception('User not logged in');
      }

      // Get all documents, sorted by timestamp (newest first)
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('water_analysis')
          .orderBy('timestamp', descending: true)
          .get();

      // Return the list of data
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get water analysis results: ${e.toString()}');
    }
  }

  // Delete a water analysis result
  Future<void> deleteWaterAnalysisResult(String analysisId) async {
    try {
      // Check if user is logged in
      if (_userId == null) {
        throw Exception('User not logged in');
      }

      // Delete the document
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('water_analysis')
          .doc(analysisId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete water analysis result: ${e.toString()}');
    }
  }
}