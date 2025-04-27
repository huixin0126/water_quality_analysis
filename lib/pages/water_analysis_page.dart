import 'package:flutter/material.dart';
import '../main.dart';
import '../services/water_potability_service.dart';

class WaterAnalysisPage extends StatefulWidget {
  const WaterAnalysisPage({Key? key}) : super(key: key);

  @override
  State<WaterAnalysisPage> createState() => _WaterAnalysisPageState();
}

class _WaterAnalysisPageState extends State<WaterAnalysisPage> {
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController();
  bool _showPlaceholder = true;
  bool _isAnalyzing = false;
  final WaterPotabilityService _potabilityService = WaterPotabilityService();

  @override
  void dispose() {
    _tdsController.dispose();
    _phController.dispose();
    _turbidityController.dispose();
    super.dispose();
  }

  void _uploadImage() {
    // Implement image upload logic
    setState(() {
      _showPlaceholder = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image uploaded successfully'),
      ),
    );
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
      
      // Analysis complete
      setState(() {
        _isAnalyzing = false;
      });
      
      // Navigate to results page with the prediction data
      Navigator.pushNamed(
        context,
        '/water_analysis_result',
        arguments: {
          'potable_probability': result['potable_probability'],
          'not_potable_probability': result['not_potable_probability'],
          'is_potable': result['is_potable'],
          'ph': ph,
          'tds': tds,
          'turbidity': _turbidityController.text.isNotEmpty ? 
            double.parse(_turbidityController.text) : null,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Analysis Water',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
            
            // Water Turbidity field
            const Text(
              'Water Turbidity (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _turbidityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter Turbidity (ppm)',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Or',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Image upload section
            GestureDetector(
              onTap: _uploadImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _showPlaceholder
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 30,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "It's empty here",
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Upload new',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 30,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Input',
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
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