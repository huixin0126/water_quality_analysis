import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analysis Options
            _buildAnalysisOption(
              context,
              title: 'Water Quality Analysis',
              icon: Icons.science,
              description: 'Check your water quality parameters',
              route: '/water_analysis',
            ),
            const SizedBox(height: 16),
            _buildAnalysisOption(
              context,
              title: 'Water Turbidity Check',
              icon: Icons.camera_alt,
              description: 'Analyze water turbidity using camera',
              route: '/water_turbidity',
            ),
            const SizedBox(height: 16),
            _buildAnalysisOption(
              context,
              title: 'Filter Replacement Prediction',
              icon: Icons.access_time,
              description: 'Predict when to replace your water filter',
              route: '/filter_prediction',
            ),
            const SizedBox(height: 16),
            _buildAnalysisOption(
              context,
              title: 'Recent Analysis Results',
              icon: Icons.bar_chart,
              description: 'View your recent water quality results',
              route: '/water_analysis_result',
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildAnalysisOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}