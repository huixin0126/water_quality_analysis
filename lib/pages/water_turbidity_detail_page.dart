import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/water_turbidity_service.dart';
import '../main.dart';

class WaterTurbidityDetailPage extends StatefulWidget {
  final String analysisId;

  const WaterTurbidityDetailPage({Key? key, required this.analysisId}) : super(key: key);

  @override
  State<WaterTurbidityDetailPage> createState() => _WaterTurbidityDetailPageState();
}

class _WaterTurbidityDetailPageState extends State<WaterTurbidityDetailPage> {
  final WaterTurbidityService _turbidityService = WaterTurbidityService();
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalysisDetails();
  }

  Future<void> _loadAnalysisDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _turbidityService.getAnalysisById(widget.analysisId);
      
      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
      
      if (data == null) {
        setState(() {
          _errorMessage = 'Analysis not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analysis details: $e';
        _isLoading = false;
      });
      debugPrint('Error loading analysis details: $e');
    }
  }

  Future<void> _deleteAnalysis() async {
    try {
      await _turbidityService.deleteAnalysis(widget.analysisId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back after deletion
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error deleting analysis: $e');
    }
  }

  String _formatDate(dynamic timestamp) {
    // Handle Firestore timestamp
    if (timestamp == null) {
      return 'Date unknown';
    }
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      date = DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch,
      );
    } else if (timestamp is String) {
      // Handle ISO date string
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }
    
    return DateFormat('MMMM d, yyyy - h:mm a').format(date);
  }

  Widget _buildConfidenceSection() {
    if (_analysisData == null || !_analysisData!.containsKey('confidence_percentages')) {
      return const SizedBox.shrink();
    }

    final confidenceMap = _analysisData!['confidence_percentages'] as Map<String, dynamic>;
    final List<MapEntry<String, dynamic>> confidenceLevels = confidenceMap.entries.toList();
    
    // Sort by confidence value in descending order
    confidenceLevels.sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Turbidity Confidence Levels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Fixed: Using a ListView for horizontal scrolling with correct constraints
            SizedBox(
              height: 100, // Fixed height for the horizontal list
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: confidenceLevels.map((entry) {
                  final String levelName = entry.key.replaceAll('_', ' ');
                  final double confidenceValue = entry.value as double;

                  return Container(
                    width: 160, // fixed width for consistency
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: confidenceValue / 100,
                          backgroundColor: Colors.grey[200],
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getConfidenceColor(confidenceValue / 100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${confidenceValue.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.lightGreen;
    if (confidence > 0.4) return Colors.amber;
    if (confidence > 0.2) return Colors.orange;
    return Colors.red;
  }

  String _getRecommendation(String highestConfidenceRange) {
    if (highestConfidenceRange.contains('below_1')) {
      return 'Water is clear and can be safe for drinking after standard disinfection. Suitable for most uses.';
    } else if (highestConfidenceRange.contains('30')) {
      return 'Water has low turbidity. Basic filtration recommended before drinking. Suitable for most uses after treatment.';
    } else if (highestConfidenceRange.contains('90')) {
      return 'Moderate turbidity detected. Use proper filtration methods and disinfection before consumption. May not be ideal for some sensitive uses.';
    } else if (highestConfidenceRange.contains('150')) {
      return 'High turbidity detected. Advanced filtration required. Not recommended for drinking without thorough treatment. Limited use applications.';
    } else {
      return 'Unknown turbidity level. Further analysis needed to determine appropriate treatment.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty || _analysisData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage.isEmpty ? 'Analysis not found' : _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalysisDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date and ID
                      Text(
                        _formatDate(_analysisData!['timestamp'] ?? _analysisData!['created_at']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.analysisId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Image
                      if (_analysisData!.containsKey('image_url') && _analysisData!['image_url'] != null)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _analysisData!['image_url'] as String,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Main results
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Water Quality Status',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _analysisData!['water_quality_status'] as String,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _turbidityService.getTurbidityColor(
                                    _analysisData!['highest_confidence_range'] as String,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              if (_analysisData!.containsKey('confidence_display') &&
                                  _analysisData!['confidence_display'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _turbidityService
                                        .getTurbidityColor(_analysisData!['highest_confidence_range'] as String)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _analysisData!['confidence_display'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _turbidityService.getTurbidityColor(
                                        _analysisData!['highest_confidence_range'] as String,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Confidence Percentages
                      _buildConfidenceSection(),
                      const SizedBox(height: 16),
                      
                      // Notes
                      if (_analysisData!.containsKey('notes') && 
                          _analysisData!['notes'] != null && 
                          (_analysisData!['notes'] as String).isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                const SizedBox(height: 8),
                                Text(
                                  _analysisData!['notes'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Recommendations
                      Card(
                        elevation: 2,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                              const SizedBox(height: 8),
                              Text(
                                _getRecommendation(_analysisData!['highest_confidence_range'] as String),
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Analysis'),
          content: const Text('Are you sure you want to delete this analysis? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAnalysis();
              },
            ),
          ],
        );
      },
    );
  }
}