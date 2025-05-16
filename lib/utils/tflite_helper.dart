import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteHelper {
  /// Helper class for TFLite model operations

  /// Safely run a TFLite model with proper input/output tensor handling
  /// Takes care of tensor shape and data type conversions
  static Future<double> runFilterPredictionModel(
    Interpreter interpreter,
    List<double> inputData,
  ) async {
    try {
      // Reshape input for the model (assuming input shape is [1, n_features])
      var input = [inputData];

      // Prepare output buffer based on output tensor shape
      var output = List.filled(1, 0.0).map((e) => [0.0]).toList(); // For output shape [1, 1]

      // Run inference
      interpreter.run(input, output);

      // Return the output value (typically a single float value)
      return output[0][0];
    } catch (e) {
      print('TFLite inference error: $e');
      rethrow;
    }
  }
  
  /// Create a mock prediction for filter life 
  /// Used as fallback when TFLite model is unavailable or fails
  static double mockFilterLifePrediction(
    double tds, 
    double turbidity, 
    double ph, 
    double depth, 
    double flowRate
  ) {
    // Base life in hours (approximately 6 months at 1 hour usage per day)
    double baseLife = 180 * 24;
    
    // Water quality factor adjustments
    double tdsImpact = math.min(0.3, tds / 1000.0) * 0.5;
    double turbidityImpact = math.min(0.2, turbidity / 10.0);
    double phImpact = math.min(0.2, math.pow((ph - 7.0).abs(), 2) / 4.0);
    double depthImpact = 0.05 - math.min(0.05, depth / 10.0);
    double flowImpact = math.min(0.15, flowRate / 100.0);
    
    // Combine factors
    double qualityReduction = tdsImpact + turbidityImpact + phImpact + flowImpact - depthImpact;
    
    // Calculate predicted life
    double predictedLife = baseLife * (1 - qualityReduction);
    
    // Add small random variation
    final random = math.Random();
    double variation = random.nextDouble() * 0.1 - 0.05; // ±5% variation
    predictedLife = predictedLife * (1 + variation);
    
    return predictedLife.clamp(720, 5000); // Min 30 days, max ~200 days
  }
  
  /// Calculate filter health percentage based on usage and predicted life
  static double calculateFilterHealth(
    double hoursUsed,
    double predictedLifeHours
  ) {
    return ((1 - hoursUsed / predictedLifeHours) * 100).clamp(0.0, 100.0);
  }
  
  /// Calculate current filter efficiency based on initial efficiency and health percentage
  static double calculateCurrentEfficiency(
    double initialEfficiency,
    double healthPercentage
  ) {
    double degradationFactor = (1 - healthPercentage / 100) * 0.5;
    return initialEfficiency * (1 - degradationFactor);
  }
}