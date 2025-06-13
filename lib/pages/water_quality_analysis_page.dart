import 'package:flutter/material.dart';
import '../services/water_quality_firestore_service.dart';

// Helper method to build quality meters
Widget _buildQualityMeter(String label, double value, double maxValue, {bool lowerIsBetter = false, bool isPhScale = false}) {
  final waterQualityService = WaterQualityFirestoreService();
  final statusColor = waterQualityService.getParameterStatusColor(label.toLowerCase(), value);
  final statusText = waterQualityService.getParameterStatusText(label.toLowerCase(), value);
  
  double percentage;
  if (isPhScale) {
    // pH Scale: optimal is 7.0, scale from 0-14
    percentage = 1.0 - (((value - 7.0).abs()) / 7.0);
  } else if (lowerIsBetter) {
    // Lower is better
    percentage = 1.0 - (value / maxValue);
  } else {
    // Higher is better
    percentage = value / maxValue;
  }
  
  // Clamp percentage between 0 and 1
  percentage = percentage.clamp(0.0, 1.0);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                isPhScale ? value.toStringAsFixed(1) : '${value.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 4),
      LinearProgressIndicator(
        value: percentage,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
        minHeight: 6,
        borderRadius: BorderRadius.circular(3),
      ),
    ],
  );
} 