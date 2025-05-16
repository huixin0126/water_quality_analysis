import 'dart:io';
import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';
import '../class/water_turbidity_model.dart';
import '../services/water_turbidity_service.dart';  // Make sure to import the service

class WaterTurbidityResultPage extends StatefulWidget {
  final File imageFile;

  const WaterTurbidityResultPage({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<WaterTurbidityResultPage> createState() => _WaterTurbidityResultPageState();
}

class _WaterTurbidityResultPageState extends State<WaterTurbidityResultPage> {
  bool _isAnalyzing = true;
  bool _isSaving = false;
  Map<String, dynamic>? _analysisResults;
  String _errorMessage = '';
  final WaterTurbidityService _turbidityService = WaterTurbidityService();
  TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    try {
      final results = await _turbidityService.analyzeTurbidityWithConfidence(widget.imageFile);
      
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

  Future<void> _saveResults() async {
    if (_analysisResults == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Add notes from the text controller if present
      if (_notesController.text.isNotEmpty) {
        _analysisResults!['notes'] = _notesController.text;
      }
      
      // Save the analysis result
      final analysisId = await _turbidityService.saveAnalysisResult(
        _analysisResults!,
        widget.imageFile,
      );
      
      setState(() {
        _isSaving = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to water analysis page after saving
      Navigator.pushReplacementNamed(context, '/analysis');
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      debugPrint('Error saving results: $e');
    }
  }

  Widget _buildTurbidityDonut(List<dynamic> detectedClasses) {
    if (detectedClasses.isEmpty) return const SizedBox.shrink();

    // Get class with highest confidence
    final maxClass = (detectedClasses as List<Map<String, dynamic>>).reduce(
      (a, b) => (a['confidence'] as double) > (b['confidence'] as double) ? a : b,
    );

    final maxConfidence = maxClass['confidence'] as double;
    final percentage = (maxConfidence * 100).clamp(0, 100);
    final className = maxClass['class_name'] as String;

    return Column(
      children: [
        const Text(
          'Turbidity Level (Percentage)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 16,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForConfidence(maxConfidence),
                ),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
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

  // Add notes field
  Widget _buildNotesField() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add notes about this sample...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
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
                      
                      // Turbidity donut
                      _buildTurbidityDonut(_analysisResults!['detected_classes'] as List<dynamic>),
                      const SizedBox(height: 24),
                      
                      // Detailed class results
                      _buildClassDetails(),
                      
                      const SizedBox(height: 24),
                      
                      // Notes field
                      _buildNotesField(),
                      
                      const SizedBox(height: 24),
                      
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
                              Text(
                                _getRecommendationFromClass(
                                  (_analysisResults!['detected_classes'] as List<dynamic>)
                                      .cast<Map<String, dynamic>>()
                                      .reduce((a, b) => (a['confidence'] as double) > (b['confidence'] as double) ? a : b)['class_name'] as String,
                                ),
                              ),
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
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveResults,
                              icon: _isSaving 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Saving...' : 'Save Results'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
  
  String _getRecommendationFromClass(String className) {
    if (className.contains('1')) {
      return 'Water is clear and can be safe for drinking after standard disinfection. Suitable for most uses.';
    } else if (className.contains('30')) {
      return 'Water has low turbidity. Basic filtration recommended before drinking. Suitable for most uses after treatment.';
    } else if (className.contains('90')) {
      return 'Moderate turbidity detected. Use proper filtration methods and disinfection before consumption. May not be ideal for some sensitive uses.';
    } else if (className.contains('150')) {
      return 'High turbidity detected. Advanced filtration required. Not recommended for drinking without thorough treatment. Limited use applications.';
    } else {
      return 'Unknown class. Further analysis needed to determine appropriate treatment.';
    }
  }
}