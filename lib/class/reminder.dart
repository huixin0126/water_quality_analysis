import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:water_quality_analysis/main.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

// Model for a Reminder
class Reminder {
  String? id;
  final String title;
  final DateTime dateTime;
  final List<int> repeatDays; // 0 = none, 1-7 = Monday-Sunday
  final String notes;
  final String type; // Water Intake, Filter Replacement, Quality Check
  final String? userId; // Add userId field

  Reminder({
    this.id,
    required this.title,
    required this.dateTime,
    required this.repeatDays,
    required this.notes,
    required this.type,
    this.userId,
  });

  // Convert Reminder to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'repeatDays': repeatDays,
      'notes': notes,
      'type': type,
      'userId': userId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Create a Reminder from a Firestore document
  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Reminder(
      id: doc.id,
      title: data['title'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      repeatDays: List<int>.from(data['repeatDays'] ?? []),
      notes: data['notes'] ?? '',
      type: data['type'] ?? 'Water Intake',
      userId: data['userId'],
    );
  }

  // Check if reminder repeats
  bool get isRepeating => repeatDays.isNotEmpty && repeatDays.any((day) => day > 0);
  
  // Get formatted date
  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateTime);
  
  // Get formatted time
  String get formattedTime => DateFormat('hh:mm a').format(dateTime);
  
  // Get repeat days as string
  String get repeatDescription {
    if (repeatDays.isEmpty || repeatDays.every((day) => day == 0)) {
      return 'No repeat';
    } else if (repeatDays.length == 7 && repeatDays.every((day) => day > 0)) {
      return 'Every day';
    } else {
      List<String> days = [];
      List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int day in repeatDays) {
        if (day > 0) {
          days.add(dayNames[day - 1]);
        }
      }
      return days.join(', ');
    }
  }
}