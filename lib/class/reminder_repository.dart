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
    
    final now = DateTime.now();
    
    // If the reminder is repeating, create separate documents for each repeat day
    if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
      // Calculate the end date (7 days from now)
      final endDate = now.add(const Duration(days: 7));
      
      // Create a base reminder data
      final baseReminderData = reminder.toMap();
      baseReminderData['userId'] = _userId;
      baseReminderData['isBaseReminder'] = true; // Mark as base reminder
      
      // Save the base reminder
      final baseDocRef = await remindersCollection.add(baseReminderData);
      
      // For each repeat day, create a separate reminder
      for (int day in reminder.repeatDays) {
        if (day > 0) { // Skip if day is 0 (no repeat)
          // Calculate the next occurrence for this day
          DateTime nextOccurrence = _getNextOccurrence(reminder.dateTime, day);
          
          // Only save if the next occurrence is within the next 7 days
          if (nextOccurrence.isBefore(endDate)) {
            // Create reminder data for this specific day
            final dayReminderData = {
              'title': reminder.title,
              'dateTime': Timestamp.fromDate(nextOccurrence),
              'repeatDays': [day], // Only include this specific day
              'notes': reminder.notes,
              'type': reminder.type,
              'userId': _userId,
              'isBaseReminder': false,
              'baseReminderId': baseDocRef.id, // Reference to the base reminder
              'createdAt': Timestamp.fromDate(now),
            };
            
            // Save the day-specific reminder
            await remindersCollection.add(dayReminderData);
          }
        }
      }
      
      return baseDocRef;
    } else {
      // For non-repeating reminders, save as normal
      final reminderData = reminder.toMap();
      reminderData['userId'] = _userId;
      reminderData['isBaseReminder'] = true;
      return await remindersCollection.add(reminderData);
    }
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
            final now = DateTime.now();
            
            for (var doc in snapshot.docs) {
              Reminder reminder = Reminder.fromFirestore(doc);
              
              // Only add if the reminder is in the future
              if (reminder.dateTime.isAfter(now)) {
                reminders.add(reminder);
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
      reminderData['userId'] = _userId;
      
      // If this is a repeating reminder, update all related reminders
      if (reminder.isRepeating) {
        // First, delete all existing day-specific reminders
        final dayReminders = await remindersCollection
            .where('baseReminderId', isEqualTo: reminder.id)
            .get();
            
        for (var doc in dayReminders.docs) {
          await doc.reference.delete();
        }
        
        // Then update the base reminder
        await remindersCollection.doc(reminder.id).update(reminderData);
        
        // Finally, create new day-specific reminders
        final now = DateTime.now();
        final endDate = now.add(const Duration(days: 7));
        
        for (int day in reminder.repeatDays) {
          if (day > 0) {
            DateTime nextOccurrence = _getNextOccurrence(reminder.dateTime, day);
            
            if (nextOccurrence.isBefore(endDate)) {
              final dayReminderData = {
                'title': reminder.title,
                'dateTime': Timestamp.fromDate(nextOccurrence),
                'repeatDays': [day],
                'notes': reminder.notes,
                'type': reminder.type,
                'userId': _userId,
                'isBaseReminder': false,
                'baseReminderId': reminder.id,
                'createdAt': Timestamp.fromDate(now),
              };
              
              await remindersCollection.add(dayReminderData);
            }
          }
        }
      } else {
        // For non-repeating reminders, just update normally
        await remindersCollection.doc(reminder.id).update(reminderData);
      }
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    // If this is a base reminder, delete all related day-specific reminders
    final doc = await remindersCollection.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isBaseReminder'] == true) {
        final dayReminders = await remindersCollection
            .where('baseReminderId', isEqualTo: id)
            .get();
            
        for (var doc in dayReminders.docs) {
          await doc.reference.delete();
        }
      }
    }
    
    // Delete the reminder itself
    await remindersCollection.doc(id).delete();
  }
}