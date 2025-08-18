import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_quality_analysis/class/water_turbidity_model.dart';

void main() {
  group('WaterQualityModel Invalid Input Tests', () {
    test('should return correct color for invalid input', () {
      expect(WaterQualityModel.getTurbidityColor(0.0), equals(Colors.grey));
    });

    test('should detect invalid input using isInvalidInput method', () {
      final validResults = {
        'is_valid_input': true,
        'estimated_ntu': 30.0,
      };
      
      final invalidResults1 = {
        'is_valid_input': false,
        'estimated_ntu': 0.0,
      };
      
      final validResults2 = {
        'is_valid_input': true,
        'estimated_ntu': 0.0, // Clear water can have 0.0 NTU
      };
      
      final invalidResults3 = {
        'is_valid_input': true,
        'estimated_ntu': 30.0,
        'error_message': 'Some error',
      };
      
      expect(WaterQualityModel.isInvalidInput(validResults), false);
      expect(WaterQualityModel.isInvalidInput(invalidResults1), true);
      expect(WaterQualityModel.isInvalidInput(validResults2), false); // Clear water is valid even with 0.0 NTU
      expect(WaterQualityModel.isInvalidInput(invalidResults3), true);
    });

    test('should have correct class info for WaterCup', () {
      expect(WaterQualityModel.classInfo[4]?['name'], 'WaterCup');
      expect(WaterQualityModel.classInfo[4]?['ntu_value'], 0.0);
      expect(WaterQualityModel.classInfo[4]?['description'], 'Not a turbidity class');
    });

    test('should have correct number of classes', () {
      expect(WaterQualityModel.numClasses, 5);
    });
  });
} 