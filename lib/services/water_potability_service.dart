import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterPotabilityService {
  // URL to your Flask API
  final String apiUrl = 'https://water-quality-analysis-w0kk.onrender.com';
  
  /// Predicts water potability based on water quality parameters
  /// Required parameters: ph, solids
  /// Optional parameters: hardness, chloramines, sulfate, conductivity, organic_carbon, trihalomethanes, turbidity
  Future<Map<String, dynamic>> predictPotability(
    double ph,
    double solids, {
    double? hardness,
    double? chloramines,
    double? sulfate,
    double? conductivity,
    double? organic_carbon,
    double? trihalomethanes,
    double? turbidity,
  }) async {
    try {
      // Prepare request body with all parameters
      final Map<String, dynamic> requestBody = {
        'ph': ph,
        'solids': solids,
      };

      // Add optional parameters if provided
      if (hardness != null) requestBody['hardness'] = hardness;
      if (chloramines != null) requestBody['chloramines'] = chloramines;
      if (sulfate != null) requestBody['sulfate'] = sulfate;
      if (conductivity != null) requestBody['conductivity'] = conductivity;
      if (organic_carbon != null) requestBody['organic_carbon'] = organic_carbon;
      if (trihalomethanes != null) requestBody['trihalomethanes'] = trihalomethanes;
      if (turbidity != null) requestBody['turbidity'] = turbidity;

      final response = await http.post(
        Uri.parse('$apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to predict water potability: ${response.statusCode}');
      }
    } catch (e) {
      // For quick testing when API is not available, return mock data
      print('Error connecting to API: $e');
      return _getMockPrediction(ph, solids);
    }
  }
  
  // Mock prediction for testing without an API
  Map<String, dynamic> _getMockPrediction(double ph, double solids) {
    // Simple logic to mimic the model prediction
    // pH between 6.5-8.5 and lower solids generally means better water
    bool isGoodPh = ph >= 6.5 && ph <= 8.5;
    bool isGoodSolids = solids < 500;
    
    double potableProbability = 0.0;
    
    if (isGoodPh && isGoodSolids) {
      potableProbability = 85.0 + (8.5 - ph).abs() * 5;
    } else if (isGoodPh || isGoodSolids) {
      potableProbability = 50.0 + (isGoodPh ? 15 : 0) + (isGoodSolids ? 15 : 0);
    } else {
      potableProbability = 30.0 - (ph < 6.5 || ph > 8.5 ? 10 : 0) - (solids > 1000 ? 10 : 0);
    }
    
    // Ensure values stay in range
    potableProbability = potableProbability.clamp(0.0, 100.0);
    
    return {
      'potable_probability': potableProbability,
      'not_potable_probability': 100 - potableProbability,
      'is_potable': potableProbability > 50,
    };
  }
}