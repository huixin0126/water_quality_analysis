import 'package:flutter/material.dart';
import '../main.dart';
import '../services/water_potability_service.dart';
import '../services/water_analysis_firestore_service.dart';

class WaterAnalysisPage extends StatefulWidget {
  const WaterAnalysisPage({Key? key}) : super(key: key);

  @override
  State<WaterAnalysisPage> createState() => _WaterAnalysisPageState();
}

class _WaterAnalysisPageState extends State<WaterAnalysisPage> {
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _solidsController = TextEditingController();
  final TextEditingController _hardnessController = TextEditingController();
  final TextEditingController _chloraminesController = TextEditingController();
  final TextEditingController _sulfateController = TextEditingController();
  final TextEditingController _conductivityController = TextEditingController();
  final TextEditingController _organicCarbonController = TextEditingController();
  final TextEditingController _trihalomethanesController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController();
  
  bool _isAnalyzing = false;
  bool _showAdvancedOptions = false;
  final WaterPotabilityService _potabilityService = WaterPotabilityService();
  final WaterAnalysisFirestoreService _firestoreService = WaterAnalysisFirestoreService();

  @override
  void dispose() {
    _phController.dispose();
    _solidsController.dispose();
    _hardnessController.dispose();
    _chloraminesController.dispose();
    _sulfateController.dispose();
    _conductivityController.dispose();
    _organicCarbonController.dispose();
    _trihalomethanesController.dispose();
    _turbidityController.dispose();
    super.dispose();
  }

  void _analyzeWater() async {
    // Validate required inputs
    if (_phController.text.isEmpty || _solidsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pH and Solids values'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final double ph = double.parse(_phController.text);
      final double solids = double.parse(_solidsController.text);
      
      // Validate ranges
      if (ph < 0 || ph > 14) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('pH must be between 0 and 14'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (solids < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solids cannot be negative'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Start analyzing
      setState(() {
        _isAnalyzing = true;
      });
      
      // Parse optional parameters
      double? hardness = _hardnessController.text.isNotEmpty ? double.parse(_hardnessController.text) : null;
      double? chloramines = _chloraminesController.text.isNotEmpty ? double.parse(_chloraminesController.text) : null;
      double? sulfate = _sulfateController.text.isNotEmpty ? double.parse(_sulfateController.text) : null;
      double? conductivity = _conductivityController.text.isNotEmpty ? double.parse(_conductivityController.text) : null;
      double? organicCarbon = _organicCarbonController.text.isNotEmpty ? double.parse(_organicCarbonController.text) : null;
      double? trihalomethanes = _trihalomethanesController.text.isNotEmpty ? double.parse(_trihalomethanesController.text) : null;
      double? turbidity = _turbidityController.text.isNotEmpty ? double.parse(_turbidityController.text) : null;
      
      // Call the prediction service
      final result = await _potabilityService.predictPotability(
        ph,
        solids,
        hardness: hardness,
        chloramines: chloramines,
        sulfate: sulfate,
        conductivity: conductivity,
        organic_carbon: organicCarbon,
        trihalomethanes: trihalomethanes,
        turbidity: turbidity,
      );
      
      // Save result to Firestore
      String analysisId = await _firestoreService.saveWaterAnalysisResult(
        ph: ph,
        tds: solids, // Keep using tds field for backward compatibility
        potableProbability: result['potable_probability'],
        isPotable: result['is_potable'],
        turbidity: turbidity,
      );
      
      // Analysis complete
      setState(() {
        _isAnalyzing = false;
      });
      
      // Navigate to results page with the analysis ID
      Navigator.pushNamed(
        context,
        '/water_analysis_result',
        arguments: {
          'analysis_id': analysisId,
        },
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildParameterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            suffixText: suffix,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/water_analysis_history');
            },
            tooltip: 'Analysis History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter water parameters to analyze potability',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Required Parameters
            const Text(
              'Required Parameters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // pH value field
            _buildParameterField(
              controller: _phController,
              label: 'pH value',
              hint: 'Enter pH',
              isRequired: true,
            ),
            
            // Solids value field
            _buildParameterField(
              controller: _solidsController,
              label: 'Solids',
              hint: 'Enter Solids',
              suffix: 'mg/L',
              isRequired: true,
            ),
            
            // Advanced Options Toggle
            Row(
              children: [
                const Text(
                  'Advanced Parameters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showAdvancedOptions,
                  onChanged: (value) {
                    setState(() {
                      _showAdvancedOptions = value;
                    });
                  },
                ),
              ],
            ),
            
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 16),
              
              // Hardness
              _buildParameterField(
                controller: _hardnessController,
                label: 'Hardness',
                hint: 'Enter Hardness',
                suffix: 'mg/L',
              ),
              
              // Chloramines
              _buildParameterField(
                controller: _chloraminesController,
                label: 'Chloramines',
                hint: 'Enter Chloramines',
                suffix: 'mg/L',
              ),
              
              // Sulfate
              _buildParameterField(
                controller: _sulfateController,
                label: 'Sulfate',
                hint: 'Enter Sulfate',
                suffix: 'mg/L',
              ),
              
              // Conductivity
              _buildParameterField(
                controller: _conductivityController,
                label: 'Conductivity',
                hint: 'Enter Conductivity',
                suffix: 'µS/cm',
              ),
              
              // Organic Carbon
              _buildParameterField(
                controller: _organicCarbonController,
                label: 'Organic Carbon',
                hint: 'Enter Organic Carbon',
                suffix: 'mg/L',
              ),
              
              // Trihalomethanes
              _buildParameterField(
                controller: _trihalomethanesController,
                label: 'Trihalomethanes',
                hint: 'Enter Trihalomethanes',
                suffix: 'µg/L',
              ),
              
              // Turbidity
              _buildParameterField(
                controller: _turbidityController,
                label: 'Turbidity',
                hint: 'Enter Turbidity',
                suffix: 'NTU',
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Analyze Button
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeWater,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing...'),
                      ],
                    )
                  : const Text('Analyze Water'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}