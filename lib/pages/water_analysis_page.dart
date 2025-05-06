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
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  bool _isAnalyzing = false;
  final WaterPotabilityService _potabilityService = WaterPotabilityService();
  final WaterAnalysisFirestoreService _firestoreService = WaterAnalysisFirestoreService();

  @override
  void dispose() {
    _tdsController.dispose();
    _phController.dispose();
    super.dispose();
  }

  void _analyzeWater() async {
    // Validate inputs
    if (_tdsController.text.isEmpty || _phController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both TDS and pH values'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final double tds = double.parse(_tdsController.text);
      final double ph = double.parse(_phController.text);
      
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
      
      if (tds < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TDS cannot be negative'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Start analyzing
      setState(() {
        _isAnalyzing = true;
      });
      
      // Call the prediction service
      final result = await _potabilityService.predictPotability(ph, tds);
      
      // Save result to Firestore
      String analysisId = await _firestoreService.saveWaterAnalysisResult(
        ph: ph,
        tds: tds,
        potableProbability: result['potable_probability'],
        isPotable: result['is_potable'],
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
          // History button to see past analysis
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
            
            // TDS value field
            const Text(
              'TDS value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tdsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter TDS',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
                suffixText: 'mg/L',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // PH value field
            const Text(
              'PH value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter PH',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
              ),
            ),
            
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