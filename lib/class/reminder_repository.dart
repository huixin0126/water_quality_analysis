import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:water_quality_analysis/class/reminder.dart';
import 'package:water_quality_analysis/main.dart';
import 'dart:math';

// Repository for managing reminders in Firestore
class ReminderRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference remindersCollection = 
      FirebaseFirestore.instance.collection('reminders');

  // Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  // Add a new reminder
  Future<DocumentReference> addReminder(Reminder reminder) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final reminderData = reminder.toMap();
    reminderData['userId'] = _userId; // Add user ID to the reminder data
    
    return await remindersCollection.add(reminderData);
  }

  // Get all reminders for the current user
  Stream<List<Reminder>> getReminders() {
    if (_userId == null) return Stream.value([]);
    
    return remindersCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('dateTime')
        .snapshots()
        .handleError((error) {
          print('Error fetching reminders: $error');
          return Stream.value([]);
        })
        .map((snapshot) {
          try {
            List<Reminder> reminders = [];
            for (var doc in snapshot.docs) {
              Reminder baseReminder = Reminder.fromFirestore(doc);
              
              // Always add the base reminder first
              reminders.add(baseReminder);
              
              if (baseReminder.isRepeating) {
                // For repeating reminders, create a separate instance for each repeat day
                for (int day in baseReminder.repeatDays) {
                  if (day > 0) { // Skip if day is 0 (no repeat)
                    // Calculate the next occurrence for this day
                    DateTime nextOccurrence = _getNextOccurrence(baseReminder.dateTime, day);
                    
                    // Create a new reminder instance for this day
                    Reminder dayReminder = Reminder(
                      id: '${baseReminder.id}_$day', // Create unique ID for each day
                      title: baseReminder.title,
                      dateTime: nextOccurrence,
                      repeatDays: [day], // Only include this specific day
                      notes: baseReminder.notes,
                      type: baseReminder.type,
                      userId: baseReminder.userId,
                    );
                    reminders.add(dayReminder);
                  }
                }
              }
            }
            
            // Sort reminders by date
            reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
            return reminders;
          } catch (e) {
            print('Error parsing reminders: $e');
            return [];
          }
        });
  }

  // Helper method to calculate next occurrence for a specific day
  DateTime _getNextOccurrence(DateTime baseDate, int targetDay) {
    DateTime now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      baseDate.hour,
      baseDate.minute,
    );
    
    // If today matches the target day and time hasn't passed, use today
    if (candidate.weekday == targetDay && candidate.isAfter(now)) {
      return candidate;
    }
    
    // Find the next occurrence of the target day
    int daysToAdd = (targetDay - now.weekday) % 7;
    if (daysToAdd == 0) {
      // If it's the same day but time has passed, go to next week
      daysToAdd = 7;
    }
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      baseDate.hour,
      baseDate.minute,
    );
  }

  // Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (reminder.id != null) {
      final reminderData = reminder.toMap();
      reminderData['userId'] = _userId; // Ensure userId is set
      await remindersCollection.doc(reminder.id).update(reminderData);
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    await remindersCollection.doc(id).delete();
  }
}