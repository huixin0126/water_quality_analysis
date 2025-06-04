import 'dart:convert';
import 'package:http/http.dart' as http;

class WaterPotabilityService {
  // URL to your Flask API (Option 1 from previous explanation)
  // If deployed locally for testing, use http://10.0.2.2:5000 for Android emulator
  // or your local IP address for physical devices
  final String apiUrl = 'https://water-quality-analysis-w0kk.onrender.com';
  
  /// Predicts water potability based on ph and tds values
  /// Returns a Map with potability probability and results
  Future<Map<String, dynamic>> predictPotability(double ph, double tds) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ph': ph,
          'tds': tds,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to predict water potability: ${response.statusCode}');
      }
    } catch (e) {
      // For quick testing when API is not available, return mock data
      // Remove this in production and handle errors properly
      print('Error connecting to API: $e');
      return _getMockPrediction(ph, tds);
    }
  }

  /// Predicts water potability based on 9 features
  /// Returns a Map with potability probability and results
  Future<Map<String, dynamic>> predictPotability9Features({
    required double ph,
    required double tds,
    required double hardness,
    required double solids,
    required double chloramines,
    required double sulfate,
    required double conductivity,
    required double organic_carbon,
    required double trihalomethanes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/predict_9features'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ph': ph,
          'tds': tds,
          'hardness': hardness,
          'solids': solids,
          'chloramines': chloramines,
          'sulfate': sulfate,
          'conductivity': conductivity,
          'organic_carbon': organic_carbon,
          'trihalomethanes': trihalomethanes,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to predict water potability: ${response.statusCode}');
      }
    } catch (e) {
      // For quick testing when API is not available, return mock data
      // Remove this in production and handle errors properly
      print('Error connecting to API: $e');
      return _getMockPrediction9Features(
        ph: ph,
        tds: tds,
        hardness: hardness,
        solids: solids,
        chloramines: chloramines,
        sulfate: sulfate,
        conductivity: conductivity,
        organicCarbon: organic_carbon,
        trihalomethanes: trihalomethanes,
      );
    }
  }
  
  // Mock prediction for testing without an API
  Map<String, dynamic> _getMockPrediction(double ph, double tds) {
    // Simple logic to mimic the model prediction
    // pH between 6.5-8.5 and lower TDS generally means better water
    bool isGoodPh = ph >= 6.5 && ph <= 8.5;
    bool isGoodTds = tds < 500;
    
    double potableProbability = 0.0;
    
    if (isGoodPh && isGoodTds) {
      potableProbability = 85.0 + (8.5 - ph).abs() * 5;
    } else if (isGoodPh || isGoodTds) {
      potableProbability = 50.0 + (isGoodPh ? 15 : 0) + (isGoodTds ? 15 : 0);
    } else {
      potableProbability = 30.0 - (ph < 6.5 || ph > 8.5 ? 10 : 0) - (tds > 1000 ? 10 : 0);
    }
    
    // Ensure values stay in range
    potableProbability = potableProbability.clamp(0.0, 100.0);
    
    return {
      'potable_probability': potableProbability,
      'not_potable_probability': 100 - potableProbability,
      'is_potable': potableProbability > 50,
    };
  }

  // Mock prediction for 9 features testing without an API
  Map<String, dynamic> _getMockPrediction9Features({
    required double ph,
    required double tds,
    required double hardness,
    required double solids,
    required double chloramines,
    required double sulfate,
    required double conductivity,
    required double organicCarbon,
    required double trihalomethanes,
  }) {
    // Simple logic to mimic the model prediction
    bool isGoodPh = ph >= 6.5 && ph <= 8.5;
    bool isGoodTds = tds < 500;
    bool isGoodHardness = hardness >= 150 && hardness <= 300;
    bool isGoodSolids = solids < 500;
    bool isGoodChloramines = chloramines >= 2 && chloramines <= 4;
    bool isGoodSulfate = sulfate < 250;
    bool isGoodConductivity = conductivity < 500;
    bool isGoodOrganicCarbon = organicCarbon < 3;
    bool isGoodTrihalomethanes = trihalomethanes < 80;
    
    double potableProbability = 0.0;
    int goodParameters = 0;
    
    if (isGoodPh) goodParameters++;
    if (isGoodTds) goodParameters++;
    if (isGoodHardness) goodParameters++;
    if (isGoodSolids) goodParameters++;
    if (isGoodChloramines) goodParameters++;
    if (isGoodSulfate) goodParameters++;
    if (isGoodConductivity) goodParameters++;
    if (isGoodOrganicCarbon) goodParameters++;
    if (isGoodTrihalomethanes) goodParameters++;
    
    // Calculate probability based on number of good parameters
    potableProbability = (goodParameters / 9) * 100;
    
    // Adjust probability based on critical parameters
    if (!isGoodPh || !isGoodTds) {
      potableProbability *= 0.7; // Reduce probability if critical parameters are not good
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