import 'package:flutter/material.dart';

class SetReminderPage extends StatefulWidget {
  const SetReminderPage({Key? key}) : super(key: key);

  @override
  _SetReminderPageState createState() => _SetReminderPageState();
}

class _SetReminderPageState extends State<SetReminderPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Water Intake';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isTimePickerVisible = false;
  bool _isDailySelected = false;
  bool _isWeeklySelected = false;
  
  // For time picker wheel
  int _selectedHour = 1;
  int _selectedMinute = 3;
  String _selectedAmPm = 'AM';

  final List<String> _reminderTypes = [
    'Water Intake',
    'Filter Replacement',
    'Quality Check',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
          'Set Reminder',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name/Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Input text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownButton(),
            const SizedBox(height: 20),
            const Text(
              'Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeSelector(),
            const SizedBox(height: 20),
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildRepeatOptions(),
            const SizedBox(height: 40),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6366F1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
              });
            }
          },
          padding: const EdgeInsets.symmetric(horizontal: 16),
          items: _reminderTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTimePickerVisible = !_isTimePickerVisible;
        });
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} $_selectedAmPm',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.access_time, color: Color(0xFF6366F1)),
              ],
            ),
          ),
          if (_isTimePickerVisible) _buildCustomTimePicker(),
        ],
      ),
    );
  }

  Widget _buildCustomTimePicker() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Hours column
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHour = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 12,
                      builder: (context, index) {
                        final hour = index == 0 ? 12 : index;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: _selectedHour == index ? FontWeight.bold : FontWeight.normal,
                              color: _selectedHour == index ? const Color(0xFF6366F1) : Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Minutes column
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinute = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 60,
                      builder: (context, index) {
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: _selectedMinute == index ? FontWeight.bold : FontWeight.normal,
                              color: _selectedMinute == index ? const Color(0xFF6366F1) : Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // AM/PM column
                Expanded(
                  child: ListWheelScrollView(
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedAmPm = index == 0 ? 'AM' : 'PM';
                      });
                    },
                    children: [
                      Center(
                        child: Text(
                          'AM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _selectedAmPm == 'AM' ? FontWeight.bold : FontWeight.normal,
                            color: _selectedAmPm == 'AM' ? const Color(0xFF6366F1) : Colors.black,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'PM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _selectedAmPm == 'PM' ? FontWeight.bold : FontWeight.normal,
                            color: _selectedAmPm == 'PM' ? const Color(0xFF6366F1) : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom action buttons
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      final now = TimeOfDay.now();
                      _selectedHour = now.hourOfPeriod;
                      _selectedMinute = now.minute;
                      _selectedAmPm = now.period == DayPeriod.am ? 'AM' : 'PM';
                    });
                  },
                  child: const Text(
                    'Now',
                    style: TextStyle(color: Color(0xFF6366F1)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isTimePickerVisible = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatOptions() {
    return Row(
      children: [
        Checkbox(
          value: _isDailySelected,
          activeColor: const Color(0xFF6366F1),
          onChanged: (value) {
            setState(() {
              _isDailySelected = value ?? false;
            });
          },
        ),
        const Text('Daily'),
        const SizedBox(width: 20),
        Checkbox(
          value: _isWeeklySelected,
          activeColor: const Color(0xFF6366F1),
          onChanged: (value) {
            setState(() {
              _isWeeklySelected = value ?? false;
            });
          },
        ),
        const Text('Weekly'),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _saveReminder() {
    // Convert the selected time for processing
    final hour = _selectedAmPm == 'AM' 
        ? (_selectedHour == 12 ? 0 : _selectedHour)
        : (_selectedHour == 12 ? 12 : _selectedHour + 12);
        
    final reminderData = {
      'name': _nameController.text,
      'type': _selectedType,
      'time': TimeOfDay(hour: hour, minute: _selectedMinute),
      'isDaily': _isDailySelected,
      'isWeekly': _isWeeklySelected,
    };
    
    // Here you can handle the saved reminder data
    // For example, passing it back to the previous screen
    Navigator.of(context).pop(reminderData);
  }
}