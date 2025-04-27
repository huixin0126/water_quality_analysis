import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class FilterPredictionPage extends StatefulWidget {
  const FilterPredictionPage({Key? key}) : super(key: key);

  @override
  State<FilterPredictionPage> createState() => _FilterPredictionPageState();
}

class _FilterPredictionPageState extends State<FilterPredictionPage> {
  final TextEditingController _waterUsageController = TextEditingController();
  final TextEditingController _installDateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _waterUsageController.dispose();
    _installDateController.dispose();
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Analysis Filter',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Daily water usage field
            const Text(
              'Daily water usage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _waterUsageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter Value',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
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
            TextField(
              controller: _installDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                hintText: 'Enter Date',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
              ),
            ),
            
            const Spacer(),
            
            // Predict Button
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: () {
                  // Implement prediction logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filter replacement date predicted'),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(150, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Predict'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}