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
    _tdsController.dispose();
    _phController.dispose();
    _hardnessController.dispose();
    _solidsController.dispose();
    _chloraminesController.dispose();
    _sulfateController.dispose();
    _conductivityController.dispose();
    _organicCarbonController.dispose();
    _trihalomethanesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _analyzeWater2Features() async {
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
        analysisType: '2features',
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
      // Parse all values
      final Map<String, double> params = {
        'ph': double.parse(_phController.text),
        'tds': double.parse(_tdsController.text),
        'hardness': double.parse(_hardnessController.text),
        'solids': double.parse(_solidsController.text),
        'chloramines': double.parse(_chloraminesController.text),
        'sulfate': double.parse(_sulfateController.text),
        'conductivity': double.parse(_conductivityController.text),
        'organic_carbon': double.parse(_organicCarbonController.text),
        'trihalomethanes': double.parse(_trihalomethanesController.text),
      };

      // Validate pH range
      if (params['ph']! < 0 || params['ph']! > 14) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('pH must be between 0 and 14'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate non-negative values
      for (var entry in params.entries) {
        if (entry.value < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${entry.key} cannot be negative'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Start analyzing
      setState(() {
        _isAnalyzing = true;
      });

      // Call the prediction service for 9 features
      final result = await _potabilityService.predictPotability9Features(params);

      // Save result to Firestore
      String analysisId = await _firestoreService.saveWaterAnalysisResult(
        ph: params['ph']!,
        tds: params['tds']!,
        potableProbability: result['potable_probability'],
        isPotable: result['is_potable'],
        analysisType: '9features',
        additionalParams: params,
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

  Widget _build2FeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Analysis (2 Features)',
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
    );
  }

  Widget _build9FeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Analysis (9 Features)',
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
          
          // pH value field
          _buildParameterField('pH', _phController),
          
          // TDS value field
          _buildParameterField('TDS', _tdsController, suffix: 'mg/L'),
          
          // Hardness value field
          _buildParameterField('Hardness', _hardnessController, suffix: 'mg/L'),
          
          // Solids value field
          _buildParameterField('Solids', _solidsController, suffix: 'mg/L'),
          
          // Chloramines value field
          _buildParameterField('Chloramines', _chloraminesController, suffix: 'mg/L'),
          
          // Sulfate value field
          _buildParameterField('Sulfate', _sulfateController, suffix: 'mg/L'),
          
          // Conductivity value field
          _buildParameterField('Conductivity', _conductivityController, suffix: 'µS/cm'),
          
          // Organic Carbon value field
          _buildParameterField('Organic Carbon', _organicCarbonController, suffix: 'mg/L'),
          
          // Trihalomethanes value field
          _buildParameterField('Trihalomethanes', _trihalomethanesController, suffix: 'µg/L'),
          
          const SizedBox(height: 24),
          
          // Analyze Button
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
    );
  }

  Widget _buildParameterField(String label, TextEditingController controller, {String? suffix}) {
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
            hintText: 'Enter $label',
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
          // History button to see past analysis
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
          _build2FeaturesTab(),
          _build9FeaturesTab(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}