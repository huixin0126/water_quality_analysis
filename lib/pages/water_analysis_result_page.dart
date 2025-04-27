import 'package:flutter/material.dart';
import '../main.dart';

class WaterAnalysisResultPage extends StatelessWidget {
  const WaterAnalysisResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the results from the arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    // Get the prediction values (with defaults if not provided)
    final double potableProbability = args['potable_probability'] ?? 72.0;
    final bool isPotable = args['is_potable'] ?? true;
    final double ph = args['ph'] ?? 7.0;
    final double tds = args['tds'] ?? 300.0;
    final double? turbidity = args['turbidity'];
    
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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