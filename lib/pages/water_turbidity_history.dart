import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/water_turbidity_service.dart';
import 'water_turbidity_detail_page.dart';
import '../main.dart';

class WaterTurbidityHistoryPage extends StatefulWidget {
  const WaterTurbidityHistoryPage({Key? key}) : super(key: key);

  @override
  State<WaterTurbidityHistoryPage> createState() => _WaterTurbidityHistoryPageState();
}

class _WaterTurbidityHistoryPageState extends State<WaterTurbidityHistoryPage> {
  final WaterTurbidityService _turbidityService = WaterTurbidityService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final history = await _turbidityService.getUserAnalysisHistory();
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history: $e';
        _isLoading = false;
      });
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _deleteAnalysis(String analysisId, int index) async {
    try {
      await _turbidityService.deleteAnalysis(analysisId);
      
      setState(() {
        _historyItems.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
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
    
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysisHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
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
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalysisHistory,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.water_drop_outlined,
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No analysis history found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Take some water samples to see your history here',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/water_turbidity');
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('New Analysis'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnalysisHistory,
                      child: ListView.builder(
                        itemCount: _historyItems.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = _historyItems[index];
                          final String id = item['id'] ?? '';
                          final String confidenceDisplay = item['confidence_display'] ?? 'Unknown';
                          final String waterQualityStatus = item['water_quality_status'] ?? 'Unknown';
                          final String imageUrl = item['image_url'] ?? '';
                          final String notes = item['notes'] ?? '';
                          final timestamp = item['timestamp'] ?? item['created_at'];
                          final String highestConfidenceRange = item['highest_confidence_range'] ?? 'Unknown';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaterTurbidityDetailPage(analysisId: id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image preview
                                  imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 150,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 150,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          height: 150,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                  
                                  // Details - FIXED: Ensure text layout uses proper constraints and width
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // FIXED: Wrap in Expanded to ensure proper text layout
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatDate(timestamp),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis, // FIXED: Handle text overflow
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    confidenceDisplay,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis, // FIXED: Handle text overflow
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // FIXED: Add some spacing
                                            const SizedBox(width: 8),
                                            // FIXED: Wrap in Expanded to prevent overflow
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _turbidityService.getTurbidityColor(highestConfidenceRange).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  waterQualityStatus,
                                                  style: TextStyle(
                                                    color: _turbidityService.getTurbidityColor(highestConfidenceRange),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          // FIXED: Ensure notes text is properly constrained
                                          SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              notes.length > 100 ? '${notes.substring(0, 100)}...' : notes,
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                _showDeleteConfirmation(id, index);
                                              },
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              label: const Text('Delete'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => WaterTurbidityDetailPage(analysisId: id),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.visibility, size: 18),
                                              label: const Text('View Details'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  void _showDeleteConfirmation(String analysisId, int index) {
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
                _deleteAnalysis(analysisId, index);
              },
            ),
          ],
        );
      },
    );
  }
}