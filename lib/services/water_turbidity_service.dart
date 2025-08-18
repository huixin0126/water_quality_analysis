import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../class/water_turbidity_model.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterTurbidityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  // Get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Analyze image and calculate percentage confidence for turbidity levels
  Future<Map<String, dynamic>> analyzeTurbidityWithConfidence(File imageFile) async {
    try {
      final model = WaterQualityModel();
      if (!model.isLoaded) {
        await model.loadModel();
      }

      final results = await model.analyzeImage(imageFile);
      
      // Debug: Print raw outputs to see all class confidences
      if (results.containsKey('raw_outputs')) {
        final rawOutputs = results['raw_outputs'] as List<double>;
        print('=== RAW MODEL OUTPUTS ===');
        print('Class 0 (Around 150 NTU): ${(rawOutputs[0] * 100).toStringAsFixed(2)}%');
        print('Class 1 (Around 30 NTU): ${(rawOutputs[1] * 100).toStringAsFixed(2)}%');
        print('Class 2 (Around 90 NTU): ${(rawOutputs[2] * 100).toStringAsFixed(2)}%');
        print('Class 3 (Below 1 NTU): ${(rawOutputs[3] * 100).toStringAsFixed(2)}%');
        print('Class 4 (WaterCup): ${(rawOutputs[4] * 100).toStringAsFixed(2)}%');
        print('=== END RAW OUTPUTS ===');
      }
      
      // Check for WaterCup in detected_classes first, even if input is invalid
      final List<dynamic> initialDetectedClasses = results['detected_classes'] as List<dynamic>;
      if (initialDetectedClasses.isNotEmpty) {
        for (var classInfo in initialDetectedClasses) {
          final String className = classInfo['class_name'] as String;
          final double confidence = (classInfo['confidence'] as double) * 100;
          
          print('Class: $className, Confidence: $confidence');
          
          // Check if this is WaterCup
          if (className == 'WaterCup') {
            print('WaterCup detected with confidence: $confidence%');
          }
        }
      }
      
      // Check if this is an invalid input
      if (WaterQualityModel.isInvalidInput(results)) {
        // For invalid inputs, set all confidence percentages to 0
        Map<String, double> confidencePercentages = {
          'NTU_below_1': 0.0,
          'Around_30_NTU': 0.0,
          'Around_90_NTU': 0.0,
          'Around_150_NTU': 0.0,
        };
        
        results['confidence_percentages'] = confidencePercentages;
        results['highest_confidence_range'] = 'Invalid_Input';
        results['confidence_display'] = 'Invalid Input';
        
        return results;
      }
      
      final List<dynamic> detectedClasses = results['detected_classes'] as List<dynamic>;

      // Match the new class names
      Map<String, double> confidencePercentages = {
        'NTU_below_1': 0.0,
        'Around_30_NTU': 0.0,
        'Around_90_NTU': 0.0,
        'Around_150_NTU': 0.0,
      };

      for (var classInfo in detectedClasses) {
        final String className = classInfo['class_name'] as String;
        final double confidence = (classInfo['confidence'] as double) * 100;
        
        print('Class: $className, Confidence: $confidence');
        print('Class name contains "WaterCup": ${className.contains('WaterCup')}');
        print('Class name contains "Not a turbidity class": ${className.contains('Not a turbidity class')}');
        print('Class name contains "cup": ${className.toLowerCase().contains('cup')}');
        print('Class name contains "not": ${className.toLowerCase().contains('not')}');

        // Skip WaterCup class as it's not a valid turbidity class
        if (className.contains('WaterCup') || 
            className.contains('Not a turbidity class') ||
            className.toLowerCase().contains('cup') ||
            className.toLowerCase().contains('not a turbidity')) {
          print('WaterCup detected with confidence: $confidence%');
          continue;
        }

        if (className.contains('1')) {
          confidencePercentages['NTU_below_1'] = 
              confidence > confidencePercentages['NTU_below_1']! ? confidence : confidencePercentages['NTU_below_1']!;
        } else if (className.contains('30')) {
          confidencePercentages['Around_30_NTU'] = 
              confidence > confidencePercentages['Around_30_NTU']! ? confidence : confidencePercentages['Around_30_NTU']!;
        } else if (className.contains('90')) {
          confidencePercentages['Around_90_NTU'] = 
              confidence > confidencePercentages['Around_90_NTU']! ? confidence : confidencePercentages['Around_90_NTU']!;
        } else if (className.contains('150')) {
          confidencePercentages['Around_150_NTU'] = 
              confidence > confidencePercentages['Around_150_NTU']! ? confidence : confidencePercentages['Around_150_NTU']!;
        }
      }

      String highestConfidenceRange = 'NTU_below_1';
      double highestConfidence = confidencePercentages['NTU_below_1']!;

      confidencePercentages.forEach((range, confidence) {
        if (confidence > highestConfidence) {
          highestConfidence = confidence;
          highestConfidenceRange = range;
        }
      });

      String displayText = '${highestConfidence.toStringAsFixed(1)}% ${highestConfidenceRange.replaceAll('_', ' ')}';

      results['confidence_percentages'] = confidencePercentages;
      results['highest_confidence_range'] = highestConfidenceRange;
      results['confidence_display'] = displayText;

      return results;
    } catch (e) {
      debugPrint('Error in turbidity analysis: $e');
      rethrow;
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile, String userId) async {
    try {
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'turbidity_images/$userId/$fileName';
      
      // Upload to Firebase Storage
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);
      
      // Wait for upload to complete and get the download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Save water turbidity analysis to Firestore
  Future<String> saveAnalysisResult(Map<String, dynamic> results, File imageFile) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if this is an invalid input
      if (WaterQualityModel.isInvalidInput(results)) {
        throw Exception('Cannot save invalid analysis results');
      }
      
      // Create a new document reference with an auto-generated ID
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('turbidity_analysis')
          .doc();
      
      // Upload the image first
      final imageUrl = await _uploadImage(imageFile, _userId!);
      
      // Create a data map for Firestore
      final data = {
        'user_id': _userId,
        'timestamp': FieldValue.serverTimestamp(),
        'estimated_ntu': results['estimated_ntu'],
        'water_quality_status': results['water_quality_status'],
        'confidence_percentages': results['confidence_percentages'],
        'highest_confidence_range': results['highest_confidence_range'],
        'confidence_display': results['confidence_display'],
        'image_url': imageUrl,
        'location': results['location'] ?? GeoPoint(0, 0), // Default if location not provided
        'notes': results['notes'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Set the data in Firestore
      await docRef.set(data);
      
      debugPrint('Analysis saved successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving analysis: $e');
      throw Exception('Failed to save analysis: $e');
    }
  }

  // Get user's analysis history
  Future<List<Map<String, dynamic>>> getUserAnalysisHistory() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('turbidity_analysis')
        .orderBy('timestamp', descending: true)
        .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting analysis history: $e');
      return [];
    }
  }

  // Get specific analysis by ID
  Future<Map<String, dynamic>?> getAnalysisById(String analysisId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('turbidity_analysis')
          .doc(analysisId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting analysis: $e');
      return null;
    }
  }

  // Delete an analysis record
  Future<void> deleteAnalysis(String analysisId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get the document first to extract image URL
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('turbidity_analysis')
          .doc(analysisId)
          .get();
      
      if (doc.exists && doc.data()!.containsKey('image_url')) {
        // Delete the image from storage
        final imageUrl = doc.data()!['image_url'] as String;
        if (imageUrl.isNotEmpty) {
          try {
            // Convert URL to storage reference path
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            debugPrint('Error deleting image file: $e');
            // Continue even if image deletion fails
          }
        }
      }
      
      // Delete the document from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('turbidity_analysis')
          .doc(analysisId)
          .delete();
      
      debugPrint('Analysis deleted successfully');
    } catch (e) {
      debugPrint('Error deleting analysis: $e');
      rethrow;
    }
  }
  
  // Get color based on turbidity level
  Color getTurbidityColor(String highestConfidenceRange) {
    switch (highestConfidenceRange) {
      case 'NTU_below_1':
        return Colors.lightBlue;
      case 'Around_30_NTU':
        return Colors.amber;
      case 'Around_90_NTU':
        return Colors.orange;
      case 'Around_150_NTU':
        return Colors.brown;
      case 'Invalid_Input':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> getLatestTurbidityData() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Query the latest turbidity analysis result
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('turbidity_analysis')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return {
        'timestamp': data['timestamp'],
        'estimated_ntu': data['estimated_ntu'] ?? 0.0,
        'water_quality_status': data['water_quality_status'] ?? 'Unknown',
        'confidence_display': data['confidence_display'] ?? 'Unknown',
      };
    } catch (e) {
      print('Error fetching turbidity data: $e');
      rethrow;
    }
  }

  // Get turbidity data for a specific time range
  Future<List<Map<String, dynamic>>> getTurbidityData(String timeRange) async {
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

      // Query the turbidity analysis results
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('turbidity_analysis')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .orderBy('timestamp', descending: false)
          .get();

      // Convert the documents to a list of maps
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'timestamp': data['timestamp'],
          'estimated_ntu': data['estimated_ntu'] ?? 0.0,
          'water_quality_status': data['water_quality_status'] ?? 'Unknown',
          'confidence_display': data['confidence_display'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error fetching turbidity data: $e');
      rethrow;
    }
  }

  // Convert turbidity data to chart data points
  List<FlSpot> convertToChartData(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value['estimated_ntu'] as double? ?? 0.0;
      return FlSpot(index, value);
    }).toList();
  }
}