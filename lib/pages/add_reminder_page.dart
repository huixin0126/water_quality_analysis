import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_quality_analysis/class/notification.dart';
import 'package:water_quality_analysis/class/reminder.dart';
import 'package:water_quality_analysis/class/reminder_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReminderPage extends StatefulWidget {
  final Reminder? reminder;
  
  const AddReminderPage({Key? key, this.reminder}) : super(key: key);

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _reminderRepository = ReminderRepository();
  final _auth = FirebaseAuth.instance;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'Water Intake';
  bool _isRepeating = false;
  List<int> _selectedDays = [];
  
  final List<String> _reminderTypes = [
    'Water Intake',
    'Filter Replacement',
    'Quality Check'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _notesController.text = widget.reminder!.notes;
      _selectedDate = widget.reminder!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.dateTime);
      _selectedType = widget.reminder!.type;
      _isRepeating = widget.reminder!.isRepeating;
      _selectedDays = List.from(widget.reminder!.repeatDays);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save reminders')),
        );
        return;
      }

      final DateTime dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reminder = Reminder(
        id: widget.reminder?.id,
        title: _titleController.text,
        dateTime: dateTime,
        repeatDays: _isRepeating ? _selectedDays : [],
        notes: _notesController.text,
        type: _selectedType,
        userId: user.uid,
      );

      if (widget.reminder == null) {
        final docRef = await _reminderRepository.addReminder(reminder);
        final savedReminder = Reminder(
          id: docRef.id,
          title: reminder.title,
          dateTime: reminder.dateTime,
          repeatDays: reminder.repeatDays,
          notes: reminder.notes,
          type: reminder.type,
          userId: reminder.userId,
        );
        await NotificationService.scheduleReminder(savedReminder);
      } else {
        await _reminderRepository.updateReminder(reminder);
        await NotificationService.cancelReminder(reminder.id);
        await NotificationService.scheduleReminder(reminder);
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reminder == null ? 'Reminder added successfully' : 'Reminder updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to reminder page
        Navigator.pushReplacementNamed(context, '/reminder');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter reminder title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: _reminderTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Repeat'),
              value: _isRepeating,
              onChanged: (value) {
                setState(() {
                  _isRepeating = value;
                  if (!value) _selectedDays.clear();
                });
              },
            ),
            if (_isRepeating) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i - 1]),
                      selected: _selectedDays.contains(i),
                      onSelected: (selected) => _toggleDay(i),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter any additional notes',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveReminder,
              child: Text(widget.reminder == null ? 'Add Reminder' : 'Update Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}