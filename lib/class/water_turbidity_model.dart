import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class WaterQualityModel {
  static const int imageSize = 224;
  static const int numClasses = 5; // Keep as 5 because model has 5 outputs
  static const double threshold = 0.3; // Using the best threshold from evaluation
  
  late Interpreter _interpreter;
  bool _isLoaded = false;

  // Class names based on actual NTU values from training
  // Index is 0-based, but class IDs in TFRecord are 1-based
  static const Map<int, Map<String, dynamic>> classInfo = {
    0: {'name': 'Around 150 NTU', 'ntu_value': 150.0, 'description': 'Highly turbid water'},
    1: {'name': 'Around 30 NTU', 'ntu_value': 30.0, 'description': 'Moderately turbid water'},
    2: {'name': 'Around 90 NTU', 'ntu_value': 90.0, 'description': 'Significantly turbid water'},
    3: {'name': 'Below 1 NTU', 'ntu_value': 1.0, 'description': 'Clear water, suitable for drinking after treatment'},
    4: {'name': 'WaterCup', 'ntu_value': 0.0, 'description': 'Not a turbidity class'}
  };

  // Singleton instance
  static final WaterQualityModel _instance = WaterQualityModel._internal();
  
  factory WaterQualityModel() => _instance;
  
  WaterQualityModel._internal();

  Future<void> loadModel() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset('assets/models/enhanced_ntu_model.tflite');
      _isLoaded = true;
      debugPrint('Water quality model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load water quality model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  bool get isLoaded => _isLoaded;

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    if (!_isLoaded) {
      await loadModel();
    }

    // Process image
    final processedImage = await _preprocessImage(imageFile);
    
    // Run inference
    final output = List<List<double>>.filled(1, List<double>.filled(numClasses, 0.0));
    
    try {
      // Input shape needs [1, 224, 224, 3] tensor
      _interpreter.run(processedImage, output);
      
      // Get results
      final results = _processResults(output[0]);
      return results;
    } catch (e) {
      debugPrint('Error during inference: $e');
      return {
        'error': 'Failed to analyze image: $e',
        'raw_outputs': [],
        'detected_classes': [],
        'estimated_ntu': 0.0,
        'water_quality_status': 'Unknown'
      };
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    // Read image
    final rawImage = img.decodeImage(await imageFile.readAsBytes());
    
    if (rawImage == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to required dimensions
    final resizedImage = img.copyResize(
      rawImage,
      width: imageSize,
      height: imageSize,
    );
    
    // Convert to float array and normalize using ImageNet stats
    // as done in the original TensorFlow code
    var inputImage = List.generate(
      imageSize,
      (y) => List.generate(
        imageSize,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          // Extract RGB values and normalize with ImageNet mean and std
          final r = ((pixel.r / 255.0) - 0.485) / 0.229;
          final g = ((pixel.g / 255.0) - 0.456) / 0.224;
          final b = ((pixel.b / 255.0) - 0.406) / 0.225;
          return [r, g, b];
        },
      ),
    );
    
    return [inputImage];
  }

  Map<String, dynamic> _processResults(List<double> outputs) {
    final waterCupConfidence = outputs[4];
    final maxNtuConfidence = outputs.take(4).reduce((a, b) => a > b ? a : b);
    final ntuAboveThreshold = outputs.take(4).any((c) => c > threshold);
    final allLow = outputs.every((c) => c < 0.2);
    
    // First check WaterCup confidence
    if (waterCupConfidence < 0.45) {
      // WaterCup confidence is low (<45%), this is NOT a WaterCup - not a valid water sample
      return {
        'raw_outputs': outputs,
        'detected_classes': [{
          'class_id': 4,
          'class_name': classInfo[4]?['name'] ?? 'WaterCup',
          'ntu_value': classInfo[4]?['ntu_value'] ?? 0.0,
          'description': classInfo[4]?['description'] ?? 'Not a turbidity class',
          'confidence': waterCupConfidence,
        }],
        'estimated_ntu': 0.0,
        'water_quality_status': 'Invalid Input - Not a water sample',
        'is_valid_input': false,
        'error_message': 'The image does not contain a water sample. Please capture an image of water for turbidity analysis.',
        'max_ntu_confidence': maxNtuConfidence,
        'water_cup_confidence': waterCupConfidence
      };
    }
    
    // WaterCup confidence is high (≥45%), this IS a WaterCup - continue with NTU detection (valid water sample)
    // More strict validation: require higher confidence for NTU classes
    final ntuAboveStrictThreshold = outputs.take(4).any((c) => c > 0.5); // Higher threshold for NTU

    // If all classes are low, mark as invalid
    if (allLow) {
      return {
        'raw_outputs': outputs,
        'detected_classes': [],
        'estimated_ntu': 0.0,
        'water_quality_status': 'Invalid Input - Unable to analyze',
        'is_valid_input': false,
        'error_message': 'Unable to detect any water turbidity characteristics. Please ensure the image contains a clear water sample with proper lighting.',
        'max_ntu_confidence': maxNtuConfidence,
        'water_cup_confidence': waterCupConfidence
      };
    }

    // Only treat as valid if NTU classes have high confidence
    if (!ntuAboveStrictThreshold) {
      return {
        'raw_outputs': outputs,
        'detected_classes': [],
        'estimated_ntu': 0.0,
        'water_quality_status': 'Invalid Input - Not a water sample',
        'is_valid_input': false,
        'error_message': 'The image does not appear to contain a water sample. Please capture an image of water for turbidity analysis.',
        'max_ntu_confidence': maxNtuConfidence,
        'water_cup_confidence': waterCupConfidence
      };
    }

    // Otherwise, treat as valid
    final predictions = List<bool>.generate(
      numClasses,
      (i) => outputs[i] > threshold,
    );
    final results = <String, dynamic>{
      'raw_outputs': outputs,
      'detected_classes': <Map<String, dynamic>>[],
      'is_valid_input': true,
    };
    for (int i = 0; i < numClasses - 1; i++) {
      if (predictions[i]) {
        results['detected_classes'].add({
          'class_id': i,
          'class_name': classInfo[i]?['name'] ?? 'Unknown',
          'ntu_value': classInfo[i]?['ntu_value'] ?? 0.0,
          'description': classInfo[i]?['description'] ?? '',
          'confidence': outputs[i],
        });
      }
    }
    // If no classes detected above threshold, but we have some confidence, add the highest confidence class
    if (results['detected_classes'].isEmpty && maxNtuConfidence > 0.1) {
      int highestConfIdx = 0;
      double highestConf = 0.0;
      for (int i = 0; i < numClasses - 1; i++) {
        if (outputs[i] > highestConf) {
          highestConf = outputs[i];
          highestConfIdx = i;
        }
      }
      results['detected_classes'].add({
        'class_id': highestConfIdx,
        'class_name': classInfo[highestConfIdx]?['name'] ?? 'Unknown',
        'ntu_value': classInfo[highestConfIdx]?['ntu_value'] ?? 0.0,
        'description': classInfo[highestConfIdx]?['description'] ?? '',
        'confidence': highestConf,
      });
    }
    final estimatedNtu = _calculateEstimatedNTU(outputs);
    results['estimated_ntu'] = estimatedNtu;
    results['water_quality_status'] = _getWaterQualityStatus(estimatedNtu);
    return results;
  }
  
  // Calculate estimated NTU using weighted average of class confidences
  double _calculateEstimatedNTU(List<double> outputs) {
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    
    // Only include NTU classes (exclude WaterCup)
    for (int i = 0; i < numClasses - 1; i++) {
      final confidence = outputs[i];
      if (confidence > threshold) {
        final ntuValue = classInfo[i]?['ntu_value'] ?? 0.0;
        weightedSum += ntuValue * confidence;
        totalWeight += confidence;
      }
    }
    
    // If no class is detected with confidence > threshold, check if it's an invalid input
    if (totalWeight <= 0.0) {
      final waterCupConfidence = outputs[4];
      final maxNtuConfidence = outputs.take(4).reduce((a, b) => a > b ? a : b);
      final allLow = outputs.every((c) => c < 0.2);
      final waterCupDominant = waterCupConfidence > maxNtuConfidence + 0.1;
      final suspiciousPattern = maxNtuConfidence < 0.4 && waterCupConfidence > 0.3;
      final ntuAboveStrictThreshold = outputs.take(4).any((c) => c > 0.5);
      
      // Check if this is an invalid input using the same logic as _processResults
      if (allLow || waterCupDominant || suspiciousPattern || !ntuAboveStrictThreshold) {
        return 0.0; // Invalid input
      }
      
      // If we have some confidence but below threshold, use the highest confidence class
      int highestConfIdx = 0;
      double highestConf = 0.0;
      
      for (int i = 0; i < numClasses - 1; i++) {
        if (outputs[i] > highestConf) {
          highestConf = outputs[i];
          highestConfIdx = i;
        }
      }
      
      return classInfo[highestConfIdx]?['ntu_value'] ?? 0.0;
    }
    
    return weightedSum / totalWeight;
  }
  
  // Get water quality status based on NTU value
  String _getWaterQualityStatus(double ntu) {
    if (ntu < 1.0) {
      return 'Excellent - Drinking water quality (after treatment)';
    } else if (ntu <= 5.0) {
      return 'Good - Suitable for drinking after standard treatment';
    } else if (ntu <= 30.0) {
      return 'Moderate - Requires treatment for drinking';
    } else if (ntu <= 90.0) {
      return 'Poor - Significant treatment required';
    } else {
      return 'Very Poor - Highly turbid, extensive treatment needed';
    }
  }
  
  // Get a color representing the turbidity level
  static Color getTurbidityColor(double ntu) {
    if (ntu == 0.0) {
      return Colors.grey; // Invalid input or non-water image
    } else if (ntu < 1.0) {
      return Colors.lightBlue; // Clear blue
    } else if (ntu <= 5.0) {
      return Colors.blue.shade300;
    } else if (ntu <= 30.0) {
      return Colors.amber.shade300;
    } else if (ntu <= 90.0) {
      return Colors.orange;
    } else {
      return Colors.brown;
    }
  }
  
  // Check if the analysis result indicates an invalid input
  static bool isInvalidInput(Map<String, dynamic> results) {
    return results['is_valid_input'] == false || 
           results.containsKey('error_message');
  }
  
  void dispose() {
    if (_isLoaded) {
      _interpreter.close();
      _isLoaded = false;
    }
  }
}