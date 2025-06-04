import 'package:flutter/material.dart';
import '../main.dart';
import '../services/water_potability_service.dart';
import '../services/water_analysis_firestore_service.dart';

class WaterAnalysisPage extends StatefulWidget {
  const WaterAnalysisPage({Key? key}) : super(key: key);

  @override
  State<WaterAnalysisPage> createState() => _WaterAnalysisPageState();
}

class _WaterAnalysisPageState extends State<WaterAnalysisPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _hardnessController = TextEditingController();
  final TextEditingController _solidsController = TextEditingController();
  final TextEditingController _chloraminesController = TextEditingController();
  final TextEditingController _sulfateController = TextEditingController();
  final TextEditingController _conductivityController = TextEditingController();
  final TextEditingController _organicCarbonController = TextEditingController();
  final TextEditingController _trihalomethanesController = TextEditingController();
  bool _isAnalyzing = false;
  final WaterPotabilityService _potabilityService = WaterPotabilityService();
  final WaterAnalysisFirestoreService _firestoreService = WaterAnalysisFirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tdsController.dispose();
    _phController.dispose();
    _hardnessController.dispose();
    _solidsController.dispose();
    _chloraminesController.dispose();
    _sulfateController.dispose();
    _conductivityController.dispose();
    _organicCarbonController.dispose();
    _trihalomethanesController.dispose();
    super.dispose();
  }

  void _analyzeWater2Features() async {
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
      
      setState(() {
        _isAnalyzing = true;
      });
      
      final result = await _potabilityService.predictPotability(ph, tds);
      
      String analysisId = await _firestoreService.saveWaterAnalysisResult(
        ph: ph,
        tds: tds,
        potableProbability: result['potable_probability'],
        isPotable: result['is_potable'],
        modelType: '2features',
      );
      
      setState(() {
        _isAnalyzing = false;
      });
      
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

  void _analyzeWater9Features() async {
    // Validate all inputs
    final controllers = {
      'pH': _phController,
      'TDS': _tdsController,
      'Hardness': _hardnessController,
      'Solids': _solidsController,
      'Chloramines': _chloraminesController,
      'Sulfate': _sulfateController,
      'Conductivity': _conductivityController,
      'Organic Carbon': _organicCarbonController,
      'Trihalomethanes': _trihalomethanesController,
    };

    for (var entry in controllers.entries) {
      if (entry.value.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter ${entry.key} value'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final double ph = double.parse(_phController.text);
      final double tds = double.parse(_tdsController.text);
      final double hardness = double.parse(_hardnessController.text);
      final double solids = double.parse(_solidsController.text);
      final double chloramines = double.parse(_chloraminesController.text);
      final double sulfate = double.parse(_sulfateController.text);
      final double conductivity = double.parse(_conductivityController.text);
      final double organicCarbon = double.parse(_organicCarbonController.text);
      final double trihalomethanes = double.parse(_trihalomethanesController.text);

      // Validate pH range
      if (ph < 0 || ph > 14) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('pH must be between 0 and 14'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate other values are non-negative
      if (tds < 0 || hardness < 0 || solids < 0 || chloramines < 0 || 
          sulfate < 0 || conductivity < 0 || organicCarbon < 0 || trihalomethanes < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All values must be non-negative'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isAnalyzing = true;
      });

      final result = await _potabilityService.predictPotability9Features(
        ph: ph,
        tds: tds,
        hardness: hardness,
        solids: solids,
        chloramines: chloramines,
        sulfate: sulfate,
        conductivity: conductivity,
        organic_carbon: organicCarbon,
        trihalomethanes: trihalomethanes,
      );

      String analysisId = await _firestoreService.saveWaterAnalysisResult(
        ph: ph,
        tds: tds,
        potableProbability: result['potable_probability'],
        isPotable: result['is_potable'],
        hardness: hardness,
        solids: solids,
        chloramines: chloramines,
        sulfate: sulfate,
        conductivity: conductivity,
        organic_carbon: organicCarbon,
        trihalomethanes: trihalomethanes,
        modelType: '9features',
      );

      setState(() {
        _isAnalyzing = false;
      });

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

  Widget _buildInputField(TextEditingController controller, String label, String hint, {String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '2 Features'),
            Tab(text: '9 Features'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 2 Features Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Water Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter pH and TDS values to analyze water potability',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInputField(_phController, 'PH value', 'Enter PH'),
                _buildInputField(_tdsController, 'TDS value', 'Enter TDS', suffix: 'mg/L'),
                ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeWater2Features,
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
          // 9 Features Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advanced Water Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter all water parameters for comprehensive analysis',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInputField(_phController, 'PH value', 'Enter PH'),
                _buildInputField(_tdsController, 'TDS value', 'Enter TDS', suffix: 'mg/L'),
                _buildInputField(_hardnessController, 'Hardness', 'Enter hardness', suffix: 'mg/L'),
                _buildInputField(_solidsController, 'Solids', 'Enter solids', suffix: 'mg/L'),
                _buildInputField(_chloraminesController, 'Chloramines', 'Enter chloramines', suffix: 'mg/L'),
                _buildInputField(_sulfateController, 'Sulfate', 'Enter sulfate', suffix: 'mg/L'),
                _buildInputField(_conductivityController, 'Conductivity', 'Enter conductivity', suffix: 'µS/cm'),
                _buildInputField(_organicCarbonController, 'Organic Carbon', 'Enter organic carbon', suffix: 'mg/L'),
                _buildInputField(_trihalomethanesController, 'Trihalomethanes', 'Enter trihalomethanes', suffix: 'µg/L'),
                ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeWater9Features,
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
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}