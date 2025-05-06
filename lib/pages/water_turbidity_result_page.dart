import 'dart:io';
import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';
import '../class/water_quality_model.dart';

class WaterTurbidityResultPage extends StatefulWidget {
  final File imageFile;

  const WaterTurbidityResultPage({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<WaterTurbidityResultPage> createState() => _WaterTurbidityResultPageState();
}

class _WaterTurbidityResultPageState extends State<WaterTurbidityResultPage> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _analysisResults;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final model = WaterQualityModel();
      if (!model.isLoaded) {
        await model.loadModel();
      }
      
      final results = await model.analyzeImage(widget.imageFile);
      
      setState(() {
        _analysisResults = results;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing image: $e';
        _isAnalyzing = false;
      });
      debugPrint(_errorMessage);
    }
  }

  Widget _buildTurbidityMeter(double ntuValue) {
    // Convert NTU to a 0-100 scale for visualization
    double score = 0;
    if (ntuValue <= 1) {
      score = ntuValue * 10; // 0-10 scale
    } else if (ntuValue <= 5) {
      score = 10 + ((ntuValue - 1) / 4) * 10; // 10-20 scale
    } else if (ntuValue <= 30) {
      score = 20 + ((ntuValue - 5) / 25) * 20; // 20-40 scale
    } else if (ntuValue <= 90) {
      score = 40 + ((ntuValue - 30) / 60) * 30; // 40-70 scale
    } else {
      score = 70 + ((ntuValue - 90) / 60) * 30; // 70-100 scale
    }
    
    return Column(
      children: [
        const Text(
          'Turbidity Level (NTU)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.lightBlue, Colors.blue, Colors.amber, Colors.orange, Colors.brown],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                left: (score / 100) * MediaQuery.of(context).size.width * 0.8,
                child: Container(
                  width: 3,
                  height: 40,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'NTU Value: ${ntuValue.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('< 1 NTU', style: TextStyle(color: Colors.lightBlue)),
            Text('< 5 NTU', style: TextStyle(color: Colors.blue)),
            Text('< 30 NTU', style: TextStyle(color: Colors.amber)),
            Text('< 90 NTU', style: TextStyle(color: Colors.orange)),
            Text('> 90 NTU', style: TextStyle(color: Colors.brown)),
          ],
        ),
      ],
    );
  }

  Widget _buildClassDetails() {
    final detectedClasses = _analysisResults!['detected_classes'] as List<dynamic>;
    
    if (detectedClasses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No specific turbidity classes detected with high confidence.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: detectedClasses.length,
          itemBuilder: (context, index) {
            final classInfo = detectedClasses[index] as Map<String, dynamic>;
            final confidence = (classInfo['confidence'] as double) * 100;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(
                  classInfo['class_name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classInfo['description'] as String),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: classInfo['confidence'] as double,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForConfidence(classInfo['confidence'] as double),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getColorForTurbidity(double ntu) {
    return WaterQualityModel.getTurbidityColor(ntu);
  }

  Color _getColorForConfidence(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.lightGreen;
    if (confidence > 0.4) return Colors.amber;
    if (confidence > 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Analyzing water turbidity...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.imageFile,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Primary result
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Water Quality Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _analysisResults!['water_quality_status'] as String,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorForTurbidity(_analysisResults!['estimated_ntu'] as double),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Turbidity meter
                      _buildTurbidityMeter(_analysisResults!['estimated_ntu'] as double),
                      const SizedBox(height: 24),
                      
                      // Detailed class results
                      _buildClassDetails(),
                      
                      const SizedBox(height: 30),
                      
                      // Water quality recommendations
                      Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommendations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(_getRecommendation(_analysisResults!['estimated_ntu'] as double)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Go back to capture another image
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('New Analysis'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement save or share functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Save feature coming soon!')),
                                );
                              },
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save Results'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
  
  String _getRecommendation(double ntuValue) {
    if (ntuValue < 1.0) {
      return 'Water is clear and can be safe for drinking after standard disinfection. Suitable for most uses.';
    } else if (ntuValue <= 5.0) {
      return 'Water has low turbidity. Basic filtration recommended before drinking. Suitable for most uses after treatment.';
    } else if (ntuValue <= 30.0) {
      return 'Moderate turbidity detected. Use proper filtration methods and disinfection before consumption. May not be ideal for some sensitive uses.';
    } else if (ntuValue <= 90.0) {
      return 'High turbidity detected. Advanced filtration required. Not recommended for drinking without thorough treatment. Limited use applications.';
    } else {
      return 'Extremely turbid water detected. Professional water treatment required. Do not consume. Not suitable for most applications without extensive treatment.';
    }
  }
}