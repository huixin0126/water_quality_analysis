import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/water_analysis_firestore_service.dart';

class WaterAnalysisHistoryPage extends StatefulWidget {
  const WaterAnalysisHistoryPage({Key? key}) : super(key: key);

  @override
  State<WaterAnalysisHistoryPage> createState() => _WaterAnalysisHistoryPageState();
}

class _WaterAnalysisHistoryPageState extends State<WaterAnalysisHistoryPage> {
  final WaterAnalysisFirestoreService _firestoreService = WaterAnalysisFirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _analysisHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await _firestoreService.getAllWaterAnalysisResults();
      
      setState(() {
        _analysisHistory = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analysis history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnalysis(String analysisId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this analysis?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete the analysis
      await _firestoreService.deleteWaterAnalysisResult(analysisId);
      
      // Reload the history
      _loadAnalysisHistory();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        // Handle Firestore Timestamp
        dateTime = timestamp.toDate();
      }
      
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildAnalysisItem(Map<String, dynamic> analysis) {
    final isPotable = analysis['is_potable'] ?? false;
    final ph = analysis['ph']?.toStringAsFixed(2) ?? 'N/A';
    final tds = analysis['tds']?.toStringAsFixed(2) ?? 'N/A';
    final formattedDate = _formatTimestamp(analysis['timestamp']);
    final modelType = analysis['model_type'] ?? '2features';
    final potableProbability = analysis['potable_probability']?.toStringAsFixed(1) ?? 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to detail page
          Navigator.pushNamed(
            context,
            '/water_analysis_result',
            arguments: {
              'analysis_id': analysis['id'],
            },
          ).then((_) => _loadAnalysisHistory()); // Refresh after coming back
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPotable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPotable ? 'Clean' : 'Not Clean',
                          style: TextStyle(
                            color: isPotable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          modelType == '2features' ? 'Basic' : 'Advanced',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteAnalysis(analysis['id']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'pH',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ph,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TDS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$tds mg/L',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Probability',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$potableProbability%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isPotable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysisHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalysisHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadAnalysisHistory,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _analysisHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.water_drop_outlined,
                                color: Colors.blue,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No analysis history yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your water analysis history will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/water_analysis');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('New Analysis'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Header
                          const Text(
                            'Your Water Analysis History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // List of analysis items
                          ..._analysisHistory
                              .map((analysis) => _buildAnalysisItem(analysis))
                              .toList(),
                        ],
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/water_analysis');
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}