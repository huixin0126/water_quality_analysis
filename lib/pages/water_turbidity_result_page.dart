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
      
      // Check for WaterCup confidence first
      final detectedClasses = results['detected_classes'] as List<dynamic>?;
      if (detectedClasses != null && detectedClasses.isNotEmpty) {
        // Find the class with the highest confidence
        final maxClass = (detectedClasses as List<Map<String, dynamic>>).reduce((a, b) => (a['confidence'] as double) > (b['confidence'] as double) ? a : b);
        final className = maxClass['class_name'] as String;
        final confidence = (maxClass['confidence'] as double) * 100;
        
        // If WaterCup confidence is low (<30%), mark as invalid
        if ((className.contains('WaterCup') || className.contains('Not a turbidity class')) && confidence < 45.0) {
          // Show alert and return to image upload page
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Invalid Image'),
              content: const Text('The image does not appear to contain a valid water sample. Please try again with a clearer image.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          // Return to image upload page
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }
      
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
    
    // Check if this is an invalid input
    if (WaterQualityModel.isInvalidInput(_analysisResults!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save invalid analysis results. Please try again with a valid water sample.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
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
    if (detectedClasses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.help_outline,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'No turbidity classes detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The image may not contain a valid water sample',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.warning_amber,
                size: 32,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                'No specific turbidity classes detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'This may indicate an invalid or unclear water sample. Please ensure the image contains a clear water sample with proper lighting.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
              : _analysisResults != null && WaterQualityModel.isInvalidInput(_analysisResults!)
                  ? _buildInvalidInputUI()
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
  
  Widget _buildInvalidInputUI() {
    final errorMessage = _analysisResults!['error_message'] as String? ?? 'Invalid input detected';
    final waterQualityStatus = _analysisResults!['water_quality_status'] as String? ?? 'Invalid Input';
    
    return SingleChildScrollView(
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
          
          // Error card
          Card(
            elevation: 3,
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    waterQualityStatus,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Tips card
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
                    'Tips for Better Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Ensure the image contains a clear water sample\n'
                    '• Use good lighting conditions\n'
                    '• Avoid shadows or reflections\n'
                    '• Make sure the water is visible and not obscured\n'
                    '• Use a clean, transparent container',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Action button
          ElevatedButton.icon(
            onPressed: () {
              // Go back to capture another image
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRecommendationFromClass(String className) {
    if (className.contains('WaterCup') || className.contains('Not a turbidity class')) {
      return 'This image does not appear to contain a valid water sample. Please capture an image of water for turbidity analysis.';
    } else if (className.contains('1')) {
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