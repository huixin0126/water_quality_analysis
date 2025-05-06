import 'package:flutter/material.dart';
import '../main.dart';
import '../services/water_analysis_firestore_service.dart';
import 'package:intl/intl.dart';

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
    final double? turbidity = _analysisData['turbidity'];
    
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
        title: const Text('Water Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Timestamp display
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Analyzed: $timestampText',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Main Result Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding( 
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: potableProbability / 100,
                            strokeWidth: 20,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                          ),
                        ),
                        Text(
                          '${potableProbability.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Result Text
                    Text(
                      resultText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      resultDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dismiss Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            minimumSize: const Size(100, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Dismiss'),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Check Filter Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/filter_prediction');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPotable 
                                ? const Color(0xFFD1FAE5) 
                                : const Color(0xFFFEE2E2),
                            foregroundColor: resultColor,
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Check Filter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Parameters Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water Parameters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // pH Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'pH Level:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ph.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (ph >= 6.5 && ph <= 8.5) 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // TDS Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TDS (mg/L):',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          tds.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (tds < 500) 
                                ? const Color(0xFF10B981) 
                                : (tds < 1000) 
                                    ? const Color(0xFFF59E0B) 
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    
                    // Turbidity Value (if provided)
                    if (turbidity != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Turbidity (NTU):',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            turbidity.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: (turbidity < 5) 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Recommendations
                    const Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPotable
                          ? '• Water is safe for consumption\n• Continue regular maintenance of your filtration system'
                          : '• Water may not be safe for consumption\n• Check your filter condition\n• Consider additional treatment methods',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
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
}