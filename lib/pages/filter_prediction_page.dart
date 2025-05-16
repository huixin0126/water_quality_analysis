import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../utils/tflite_helper.dart'; // Use dedicated helper class
import '../models/filter_model.dart'; // New model class
import 'filter_prediction_result.dart';
import 'filter_prediction_history_page.dart';

class FilterPredictionPage extends StatefulWidget {
  // Add optional parameters to receive water quality data
  final Map<String, dynamic>? initialParams;
  
  const FilterPredictionPage({
    Key? key,
    this.initialParams,
  }) : super(key: key);

  @override
  State<FilterPredictionPage> createState() => _FilterPredictionPageState();
}

class _FilterPredictionPageState extends State<FilterPredictionPage> {
  final TextEditingController _waterUsageController = TextEditingController();
  final TextEditingController _installDateController = TextEditingController();
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController(); // Added turbidity
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  bool _modelLoadError = false;

  // Default values for water quality parameters - Initialize with non-null values
  Map<String, dynamic> _modelMetadata = {
    "feature_defaults": [250.0, 5.0, 7.0, 2.75, 50.0],
    "feature_ranges": {
      "tds": [0.01, 500.0],
      "turbidity": [0.1, 20.0],
      "ph": [6.0, 8.5],
      "depth": [1.0, 5.0],
      "flow_rate": [20.0, 100.0]
    }
  };
  
  Interpreter? _lifeInterpreter;
  Interpreter? _efficiencyInterpreter;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    _loadModels();
    
    // Apply initial parameters if provided
    if (widget.initialParams != null) {
      _applyInitialParameters();
    }
  }

  // New method to apply initial parameters
  void _applyInitialParameters() {
    final params = widget.initialParams!;
    
    // Set pH value if provided
    if (params['ph'] != null) {
      _phController.text = params['ph'].toString();
    }
    
    // Set TDS value if provided
    if (params['tds'] != null) {
      _tdsController.text = params['tds'].toString();
    }
    
    // Set turbidity value if provided
    if (params['turbidity'] != null) {
      _turbidityController.text = params['turbidity'].toString();
    }
    
    // Auto-expand advanced options if we received water parameters
    if (params['ph'] != null || params['tds'] != null || params['turbidity'] != null) {
      setState(() {
        _showAdvancedOptions = true;
      });
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _modelLoadError = false;
    });

    try {
      // Load model metadata from assets
      final String metadataContent = await rootBundle.loadString('assets/models/sample_test_data.json');
      final parsedMetadata = json.decode(metadataContent);
      
      if (parsedMetadata != null) {
        setState(() {
          _modelMetadata = parsedMetadata;
        });
        
        // Set default values for optional parameters - only if not already set from initialParams
        if (widget.initialParams == null || widget.initialParams!['tds'] == null) {
          if (_modelMetadata['feature_defaults'] != null && _modelMetadata['feature_defaults'].length >= 3) {
            _tdsController.text = _modelMetadata['feature_defaults'][0].toString();
          } else {
            _tdsController.text = '250.0';
          }
        }
        
        if (widget.initialParams == null || widget.initialParams!['turbidity'] == null) {
          if (_modelMetadata['feature_defaults'] != null && _modelMetadata['feature_defaults'].length >= 3) {
            _turbidityController.text = _modelMetadata['feature_defaults'][1].toString();
          } else {
            _turbidityController.text = '5.0';
          }
        }
        
        if (widget.initialParams == null || widget.initialParams!['ph'] == null) {
          if (_modelMetadata['feature_defaults'] != null && _modelMetadata['feature_defaults'].length >= 3) {
            _phController.text = _modelMetadata['feature_defaults'][2].toString();
          } else {
            _phController.text = '7.0';
          }
        }
      } else {
        throw Exception('Model metadata is null');
      }
      
      // Create interpreter options with potential fixes for compatibility issues
      final interpreterOptions = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;  // Disable Android Neural Networks API which can cause issues
      
      // Load TFLite models with options
      try {
        _lifeInterpreter = await Interpreter.fromAsset(
          'assets/models/filter_life_model.tflite',
          options: interpreterOptions,
        );
        
        _efficiencyInterpreter = await Interpreter.fromAsset(
          'assets/models/filter_efficiency_model.tflite',
          options: interpreterOptions,
        );
        
        print('Models loaded successfully');
      } catch (e) {
        print('Error loading TFLite models: $e');
        setState(() {
          _modelLoadError = true;
        });
        // Fall back to mock models for testing UI
        _setupMockModels();
      }
    } catch (e) {
      print('Error in model setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load prediction models: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadModels,
            ),
          ),
        );
      }
      // Fall back to mock models
      _setupMockModels();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Set up mock models for testing when TFLite models fail to load
  void _setupMockModels() {
    print('Setting up mock models for testing UI');
    // We'll implement mock prediction logic instead of using TFLite
    _modelMetadata = {
      "model_version": "1.0.0",
      "description": "Mock water filter prediction models",
      "feature_names": ["tds", "turbidity", "ph", "depth", "flow_rate"],
      "feature_defaults": [250.0, 5.0, 7.0, 2.75, 50.0],
      "feature_ranges": {
        "tds": [0.01, 500.0],
        "turbidity": [0.1, 20.0],
        "ph": [6.0, 8.5],
        "depth": [1.0, 5.0],
        "flow_rate": [20.0, 100.0]
      }
    };
    
    // Only set default values if not already set from initialParams
    if (_tdsController.text.isEmpty) {
      _tdsController.text = '250.0';
    }
    
    if (_turbidityController.text.isEmpty) {
      _turbidityController.text = '5.0';
    }
    
    if (_phController.text.isEmpty) {
      _phController.text = '7.0';
    }
  }

  @override
  void dispose() {
    _waterUsageController.dispose();
    _installDateController.dispose();
    _tdsController.dispose();
    _phController.dispose();
    _turbidityController.dispose();
    _lifeInterpreter?.close();
    _efficiencyInterpreter?.close();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _installDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<Map<String, dynamic>> _predictFilterLife() async {
    if (_selectedDate == null) {
      throw Exception('Installation date not selected');
    }

    if (_waterUsageController.text.isEmpty) {
      throw Exception('Daily water usage not specified');
    }

    // Parse inputs with validation
    final double dailyUsageHours = _parseDoubleWithValidation(
      _waterUsageController.text, 
      'Daily usage hours', 
      0.1, 
      24.0
    );
    
    // Safely access feature ranges with null checks
    double minTds = 0.01;
    double maxTds = 500.0;
    if (_modelMetadata['feature_ranges'] != null && 
        _modelMetadata['feature_ranges']['tds'] != null &&
        _modelMetadata['feature_ranges']['tds'].length >= 2) {
      minTds = _modelMetadata['feature_ranges']['tds'][0];
      maxTds = _modelMetadata['feature_ranges']['tds'][1];
    }
    
    double minTurbidity = 0.1;
    double maxTurbidity = 20.0;
    if (_modelMetadata['feature_ranges'] != null && 
        _modelMetadata['feature_ranges']['turbidity'] != null &&
        _modelMetadata['feature_ranges']['turbidity'].length >= 2) {
      minTurbidity = _modelMetadata['feature_ranges']['turbidity'][0];
      maxTurbidity = _modelMetadata['feature_ranges']['turbidity'][1];
    }
    
    double minPh = 6.0;
    double maxPh = 8.5;
    if (_modelMetadata['feature_ranges'] != null && 
        _modelMetadata['feature_ranges']['ph'] != null &&
        _modelMetadata['feature_ranges']['ph'].length >= 2) {
      minPh = _modelMetadata['feature_ranges']['ph'][0];
      maxPh = _modelMetadata['feature_ranges']['ph'][1];
    }
    
    final double tds = _parseDoubleWithValidation(
      _tdsController.text, 
      'TDS', 
      minTds, 
      maxTds
    );
    
    final double turbidity = _parseDoubleWithValidation(
      _turbidityController.text, 
      'Turbidity', 
      minTurbidity, 
      maxTurbidity
    );
    
    final double ph = _parseDoubleWithValidation(
      _phController.text, 
      'pH', 
      minPh, 
      maxPh
    );
    
    // Use default values for depth and flow rate with safe access
    double depth = 2.75;
    double flowRate = 50.0;
    
    if (_modelMetadata['feature_defaults'] != null && _modelMetadata['feature_defaults'].length >= 5) {
      depth = _modelMetadata['feature_defaults'][3] ?? 2.75;
      flowRate = _modelMetadata['feature_defaults'][4] ?? 50.0;
    }

    double predictedLifeHours;
    double predictedEfficiency;

    // If TFLite models are loaded, use them for prediction
    if (_lifeInterpreter != null && _efficiencyInterpreter != null && !_modelLoadError) {
      try {
        // Use the TfliteHelper class for predictions
        final inputData = [tds, turbidity, ph, depth, flowRate];
        
        // Run inference for filter life
        predictedLifeHours = await TfliteHelper.runFilterPredictionModel(
          _lifeInterpreter!,
          inputData,
        );

        // Run inference for filter efficiency
        predictedEfficiency = await TfliteHelper.runFilterPredictionModel(
          _efficiencyInterpreter!,
          inputData,
        );
      } catch (e) {
        print('Error during TFLite inference: $e');
        // Fall back to mock prediction if TFLite inference fails
        return _mockPredictionCalculation(dailyUsageHours, tds, turbidity, ph);
      }
    } else {
      // Use mock prediction calculation if models aren't loaded
      return _mockPredictionCalculation(dailyUsageHours, tds, turbidity, ph);
    }

    // Calculate results based on model outputs
    final results = _calculateResults(
      dailyUsageHours,
      predictedLifeHours,
      predictedEfficiency,
      tds,
      turbidity,
      ph
    );

    return results;
  }

  // Parse input with validation
  double _parseDoubleWithValidation(String value, String fieldName, double min, double max) {
    try {
      final parsedValue = double.parse(value);
      if (parsedValue < min || parsedValue > max) {
        throw Exception('$fieldName must be between $min and $max');
      }
      return parsedValue;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$fieldName must be a valid number');
    }
  }

  // Calculate results based on predicted life and efficiency
  Map<String, dynamic> _calculateResults(
    double dailyUsageHours,
    double predictedLifeHours,
    double predictedEfficiency,
    double tds,
    double turbidity,
    double ph
  ) {
    final DateTime now = DateTime.now();
    final int daysSinceInstallation = now.difference(_selectedDate!).inDays;
    final double hoursUsed = daysSinceInstallation * dailyUsageHours;

    // Calculate health percentage
    final double healthPercentage = TfliteHelper.calculateFilterHealth(
      hoursUsed,
      predictedLifeHours
    );

    // Calculate replacement date
    final double remainingHours = (predictedLifeHours - hoursUsed).clamp(0.0, double.infinity);
    final double remainingDays = remainingHours / dailyUsageHours;
    final DateTime replacementDate = now.add(Duration(days: remainingDays.round()));

    // Calculate current efficiency
    final double currentEfficiency = TfliteHelper.calculateCurrentEfficiency(
      predictedEfficiency,
      healthPercentage
    );

    return FilterModel(
      installationDate: _selectedDate!.toIso8601String(),
      currentDate: now.toIso8601String(),
      daysInUse: daysSinceInstallation,
      hoursUsed: hoursUsed,
      predictedLifeHours: predictedLifeHours,
      healthPercentage: healthPercentage,
      replacementDate: replacementDate.toIso8601String(),
      daysUntilReplacement: remainingDays.round(),
      currentEfficiency: currentEfficiency,
      initialEfficiency: predictedEfficiency,
      tds: tds,
      turbidity: turbidity,
      ph: ph,
      dailyUsageHours: dailyUsageHours,
    ).toJson();
  }

  // Fallback method for when TFLite models aren't available
  Map<String, dynamic> _mockPredictionCalculation(
    double dailyUsageHours,
    double tds,
    double turbidity,
    double ph,
  ) {
    final DateTime now = DateTime.now();
    final int daysSinceInstallation = now.difference(_selectedDate!).inDays;
    final double hoursUsed = daysSinceInstallation * dailyUsageHours;

    // Basic heuristics for mock predictions
    double predictedLifeHours = 1500.0 - (tds * 1.2 + turbidity * 10 + (7.0 - ph).abs() * 50);
    predictedLifeHours = predictedLifeHours.clamp(500.0, 2000.0); // Clamp values

    double predictedEfficiency = 95.0 - (tds / 10 + turbidity * 2 + (7.0 - ph).abs() * 3);
    predictedEfficiency = predictedEfficiency.clamp(50.0, 99.0); // Clamp values

    final double healthPercentage = TfliteHelper.calculateFilterHealth(
      hoursUsed,
      predictedLifeHours,
    );

    final double remainingHours = (predictedLifeHours - hoursUsed).clamp(0.0, double.infinity);
    final double remainingDays = remainingHours / dailyUsageHours;
    final DateTime replacementDate = now.add(Duration(days: remainingDays.round()));

    final double currentEfficiency = TfliteHelper.calculateCurrentEfficiency(
      predictedEfficiency,
      healthPercentage,
    );

    return FilterModel(
      installationDate: _selectedDate!.toIso8601String(),
      currentDate: now.toIso8601String(),
      daysInUse: daysSinceInstallation,
      hoursUsed: hoursUsed,
      predictedLifeHours: predictedLifeHours,
      healthPercentage: healthPercentage,
      replacementDate: replacementDate.toIso8601String(),
      daysUntilReplacement: remainingDays.round(),
      currentEfficiency: currentEfficiency,
      initialEfficiency: predictedEfficiency,
      tds: tds,
      turbidity: turbidity,
      ph: ph,
      dailyUsageHours: dailyUsageHours,
    ).toJson();
  }

  Future<void> _savePredictionToFirestore(Map<String, dynamic> result) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final DocumentReference docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('filter_prediction')
          .doc();

      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        ...result,
      });

      print('Prediction saved to Firestore');
    } catch (e) {
      print('Error saving to Firestore: $e');
      rethrow;
    }
  }

  Future<void> _handlePrediction() async {
    // Clear previous errors
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    
    // Input validation
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an installation date')),
        );
      }
      return;
    }
    
    if (_waterUsageController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter daily water usage')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _predictFilterLife();
      await _savePredictionToFirestore(result);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to the result page with the prediction data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilterPredictionResultPage(
              predictionData: result,
            ),
          ),
        );
      }
    } catch (e) {
      print('Prediction error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Replacement Prediction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_modelLoadError)
            Tooltip(
              message: 'Using fallback prediction (models failed to load)',
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[800],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Prediction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilterPredictionHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing prediction...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (_modelLoadError)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber[800],
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Using approximate predictions (ML models failed to load)',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Daily water usage field
                    const Text(
                      'Daily water usage (hours)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _waterUsageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter hours of usage per day',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        errorText: _waterUsageController.text.isNotEmpty && 
                                  (double.tryParse(_waterUsageController.text) ?? 0) <= 0
                              ? 'Must be greater than 0'
                              : null,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Filter installation date field
                    const Text(
                      'Filter installation date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          suffixIcon: const Icon(Icons.calendar_today),
                          errorText: _selectedDate == null ? 'Required' : null,
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select installation date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Advanced options toggle
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _showAdvancedOptions
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            color: const Color(0xFF6366F1),
                          ),
                          const Text(
                            'Advanced Options',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      
                      // TDS field
                      const Text(
                        'TDS (mg/l)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tdsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Enter TDS value (0.01-500)',
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          helperText: 'Total Dissolved Solids',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Turbidity field
                      const Text(
                        'Turbidity (NTU)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _turbidityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Enter turbidity value (0.1-20)',
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          helperText: 'Water cloudiness measure',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // pH field
                      const Text(
                        'pH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Enter pH value (6.0-8.5)',
                          filled: true,
                          fillColor: Color(0xFFF3F4F6),
                          helperText: 'Acidity/alkalinity measure',
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Predict Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _handlePrediction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Predict',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}