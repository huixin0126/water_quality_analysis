import 'package:flutter/material.dart';
import '../main.dart';
import '../services/water_analysis_firestore_service.dart';
import 'package:intl/intl.dart';
import 'filter_prediction_page.dart'; // Make sure to import this

class WaterAnalysisResultPage extends StatefulWidget {
  const WaterAnalysisResultPage({Key? key}) : super(key: key);

  @override
  State<WaterAnalysisResultPage> createState() => _WaterAnalysisResultPageState();
}

class _WaterAnalysisResultPageState extends State<WaterAnalysisResultPage> {
  final WaterAnalysisFirestoreService _firestoreService = WaterAnalysisFirestoreService();
  bool _isLoading = true;
  Map<String, dynamic> _analysisData = {};
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the analysis ID from the route arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      final String? analysisId = args['analysis_id'];

      if (analysisId == null) {
        throw Exception('Missing analysis ID');
      }

      // Fetch the data from Firestore
      _analysisData = await _firestoreService.getWaterAnalysisResult(analysisId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Water Analysis Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      );
    }

    // Handle error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Water Analysis Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      );
    }

    // Get the values from the data
    final double potableProbability = _analysisData['potable_probability'] ?? 0.0;
    final bool isPotable = _analysisData['is_potable'] ?? false;
    final double ph = _analysisData['ph'] ?? 7.0;
    final double tds = _analysisData['tds'] ?? 0.0;
    final String modelType = _analysisData['model_type'] ?? '2features';
    
    // Format timestamp (if available)
    String timestampText = 'N/A';
    if (_analysisData['timestamp'] != null) {
      final timestamp = _analysisData['timestamp'].toDate();
      timestampText = DateFormat('MMM d, yyyy - h:mm a').format(timestamp);
    }
    
    // Determine the result color and text
    final Color resultColor = isPotable ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final String resultText = isPotable ? 'Clean' : 'Not Clean';
    final String resultDescription = isPotable
        ? 'Your water sample is Clean. If you need more information about your filter health, click the button below:'
        : 'Your water sample is Not Clean. We recommend additional filtration or treatment. Check your filter status:';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: resultColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPotable ? Icons.check_circle : Icons.warning,
                            color: resultColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resultText,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor,
                                ),
                              ),
                              Text(
                                'Analysis completed at $timestampText',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      resultDescription,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    // Probability Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Potability Probability',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: potableProbability / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${potableProbability.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Parameters Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelType == '2features' ? 'Basic Parameters' : 'Water Parameters',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildParameterRow('pH', ph.toStringAsFixed(2)),
                    _buildParameterRow('TDS', '${tds.toStringAsFixed(2)} mg/L'),
                    if (modelType == '9features') ...[
                      _buildParameterRow('Hardness', '${_analysisData['hardness']?.toStringAsFixed(2) ?? 'N/A'} mg/L'),
                      _buildParameterRow('Solids', '${_analysisData['solids']?.toStringAsFixed(2) ?? 'N/A'} mg/L'),
                      _buildParameterRow('Chloramines', '${_analysisData['chloramines']?.toStringAsFixed(2) ?? 'N/A'} mg/L'),
                      _buildParameterRow('Sulfate', '${_analysisData['sulfate']?.toStringAsFixed(2) ?? 'N/A'} mg/L'),
                      _buildParameterRow('Conductivity', '${_analysisData['conductivity']?.toStringAsFixed(2) ?? 'N/A'} µS/cm'),
                      _buildParameterRow('Organic Carbon', '${_analysisData['organic_carbon']?.toStringAsFixed(2) ?? 'N/A'} mg/L'),
                      _buildParameterRow('Trihalomethanes', '${_analysisData['trihalomethanes']?.toStringAsFixed(2) ?? 'N/A'} µg/L'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/filter_prediction');
                    },
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Check Filter Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/analysis');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
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

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}