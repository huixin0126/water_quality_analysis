import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_quality_analysis/main.dart';

class WaterReminderItem {
  final String title;
  final TimeOfDay time;
  
  WaterReminderItem({required this.title, required this.time});
  
  String get formattedTime {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat('hh:mm a');
    return format.format(dt);
  }
}

class WaterIntakeReminderPage extends StatefulWidget {
  const WaterIntakeReminderPage({Key? key}) : super(key: key);

  @override
  _WaterIntakeReminderPageState createState() => _WaterIntakeReminderPageState();
}

class _WaterIntakeReminderPageState extends State<WaterIntakeReminderPage> {
  final List<WaterReminderItem> _reminderItems = [
    WaterReminderItem(
      title: '1 Cup of Water',
      time: const TimeOfDay(hour: 8, minute: 0),
    ),
    WaterReminderItem(
      title: '1 Cup of Water',
      time: const TimeOfDay(hour: 12, minute: 0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Water Intake Reminder',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Water Reminder Lists',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _reminderItems.length,
              itemBuilder: (context, index) {
                final item = _reminderItems[index];
                return _buildReminderCard(item);
              },
            ),
          ),
        ],
      ),
      // Use the existing BottomNavBar component from main.dart
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: SizedBox(
          width: 200,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF6366F1),
            onPressed: _addNewReminder,
            label: const Text(
              'Add Reminder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReminderCard(WaterReminderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedTime,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _editReminder(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(60, 36),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewReminder() async {
    // Show dialog to add a new reminder
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      setState(() {
        _reminderItems.add(
          WaterReminderItem(
            title: '1 Cup of Water',
            time: pickedTime,
          ),
        );
      });
    }
  }

  void _editReminder(WaterReminderItem item) async {
    // Show dialog to edit the reminder
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: item.time,
    );
    
    if (pickedTime != null) {
      final index = _reminderItems.indexOf(item);
      setState(() {
        _reminderItems[index] = WaterReminderItem(
          title: item.title,
          time: pickedTime,
        );
      });
    }
  }
}