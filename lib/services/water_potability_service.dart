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
  Future<Map<String, dynamic>> predictPotability9Features(Map<String, double> params) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/predict_9features'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(params),
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
      return _getMockPrediction9Features(params);
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

  // Mock prediction for 9-feature analysis
  Map<String, dynamic> _getMockPrediction9Features(Map<String, double> params) {
    // Define optimal ranges for each parameter
    bool isGoodPh = params['ph']! >= 6.5 && params['ph']! <= 8.5;
    bool isGoodHardness = params['hardness']! >= 150 && params['hardness']! <= 300;
    bool isGoodSolids = params['solids']! <= 500; // TDS
    bool isGoodChloramines = params['chloramines']! >= 2 && params['chloramines']! <= 4;
    bool isGoodSulfate = params['sulfate']! <= 250;
    bool isGoodConductivity = params['conductivity']! <= 500;
    bool isGoodOrganicCarbon = params['organic_carbon']! <= 2.5;
    bool isGoodTrihalomethanes = params['trihalomethanes']! <= 80;
    bool isGoodTurbidity = params['turbidity']! <= 5;
    
    // Count good parameters
    int goodParams = 0;
    if (isGoodPh) goodParams++;
    if (isGoodHardness) goodParams++;
    if (isGoodSolids) goodParams++;
    if (isGoodChloramines) goodParams++;
    if (isGoodSulfate) goodParams++;
    if (isGoodConductivity) goodParams++;
    if (isGoodOrganicCarbon) goodParams++;
    if (isGoodTrihalomethanes) goodParams++;
    if (isGoodTurbidity) goodParams++;
    
    // Calculate base probability based on number of good parameters
    double potableProbability = (goodParams / 9) * 100;
    
    // Adjust probability based on critical parameters
    if (!isGoodPh || !isGoodSolids) {
      potableProbability *= 0.7; // Reduce probability if critical parameters are not good
    }
    
    // Additional adjustments based on parameter values
    if (params['ph']! < 6.0 || params['ph']! > 9.0) {
      potableProbability *= 0.8; // Further reduce if pH is far from optimal
    }
    
    if (params['solids']! > 1000) {
      potableProbability *= 0.8; // Further reduce if TDS is very high
    }
    
    if (params['turbidity']! > 10) {
      potableProbability *= 0.9; // Slightly reduce if turbidity is high
    }
    
    // Ensure values stay in range
    potableProbability = potableProbability.clamp(0.0, 100.0);
    
    return {
      'potable_probability': potableProbability,
      'not_potable_probability': 100 - potableProbability,
      'is_potable': potableProbability > 50,
      'parameter_status': {
        'ph': isGoodPh ? 'Good' : 'Poor',
        'hardness': isGoodHardness ? 'Good' : 'Poor',
        'solids': isGoodSolids ? 'Good' : 'Poor',
        'chloramines': isGoodChloramines ? 'Good' : 'Poor',
        'sulfate': isGoodSulfate ? 'Good' : 'Poor',
        'conductivity': isGoodConductivity ? 'Good' : 'Poor',
        'organic_carbon': isGoodOrganicCarbon ? 'Good' : 'Poor',
        'trihalomethanes': isGoodTrihalomethanes ? 'Good' : 'Poor',
        'turbidity': isGoodTurbidity ? 'Good' : 'Poor',
      }
    };
  }
}