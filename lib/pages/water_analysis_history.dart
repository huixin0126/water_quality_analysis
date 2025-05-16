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
              // Date and status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPotable ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPotable ? 'Potable' : 'Not Potable',
                      style: TextStyle(
                        color: isPotable ? Colors.green.shade700 : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Parameters row
              Row(
                children: [
                  _buildParameterChip(Icons.opacity, 'pH', ph),
                  const SizedBox(width: 12),
                  _buildParameterChip(Icons.water_drop, 'TDS', '$tds mg/L'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View details button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/water_analysis_result',
                        arguments: {
                          'analysis_id': analysis['id'],
                        },
                      ).then((_) => _loadAnalysisHistory());
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                  
                  // Delete button
                  IconButton(
                    onPressed: () => _deleteAnalysis(analysis['id']),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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