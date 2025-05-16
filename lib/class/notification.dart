import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:water_quality_analysis/class/reminder.dart';
import 'package:water_quality_analysis/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

// Service for managing notifications
class NotificationService {
  static bool _isInitialized = false;
  static int _badgeCount = 0;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final Random _random = Random();

  // Get a unique ID for each notification
  static int _getUniqueId() {
    return _random.nextInt(2147483647);
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone with local timezone
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
      debugPrint('Initialized timezone: ${tz.local.name}');
    } catch (e) {
      debugPrint('Error setting timezone: $e');
      // Fallback to local device timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      debugPrint('Falling back to device timezone: $timeZoneName');
    }
    
    // Initialize notifications with basic settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Handle notifications that are tapped by the user
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped with payload: ${response.payload}');
        // You can handle navigation or other actions here
      },
    );

    // Set up Android notification channel
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Notifications for water quality reminders',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
          ),
        );
      }
    }
    
    _isInitialized = true;
    debugPrint('Notification service initialized successfully');
    
    // Test an immediate notification to confirm initialization
    _showTestNotification('Notification Service Started', 
      'Notification system is working properly. You should see scheduled notifications when they are due.');
  }

  // Show a test notification immediately
  static Future<void> _showTestNotification(String title, String body) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for water quality reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _notifications.show(
      _getUniqueId(),
      title,
      body, 
      notificationDetails,
      payload: 'test_notification',
    );
    
    debugPrint('Test notification shown: $title - $body');
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isInitialized) {
      await initialize();
    }

    final DateTime now = DateTime.now();
    DateTime scheduledDate = reminder.dateTime;
    
    debugPrint('Current time: ${now.toString()}');
    debugPrint('Scheduled time: ${scheduledDate.toString()}');
    debugPrint('Repeat days: ${reminder.repeatDays}');
    
    // If the date is in the past, move it to the next occurrence
    if (scheduledDate.isBefore(now)) {
      if (reminder.isRepeating) {
        scheduledDate = _findNextOccurrence(reminder, now);
        debugPrint('Adjusted to next occurrence: ${scheduledDate.toString()}');
      } else {
        debugPrint('Reminder is in the past and not repeating, skipping');
        return;
      }
    }

    // Create notification details with maximum priority
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for water quality reminders',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: true,
      enableLights: true,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    try {
      // Calculate the exact time difference
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      final nowTZ = tz.TZDateTime.now(tz.local);
      final difference = scheduledTZ.difference(nowTZ);
      
      debugPrint('Time until notification: ${difference.inMinutes} minutes and ${difference.inSeconds % 60} seconds');
      debugPrint('Scheduled TZDateTime: $scheduledTZ');
      debugPrint('Current TZDateTime: $nowTZ');

      // Cancel any existing notifications for this reminder
      if (reminder.id != null) {
        try {
          debugPrint('Cancelling existing notification for reminder ID: ${reminder.id}');
          await _notifications.cancel(reminder.id.hashCode);
          debugPrint('Successfully cancelled existing notification');
        } catch (e) {
          debugPrint('No existing notification to cancel or error cancelling: $e');
        }
      }

      // For repeating reminders, schedule each day separately
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        for (int day in reminder.repeatDays) {
          // Create a unique ID for each day's notification
          final dayId = reminder.id.hashCode + day;
          
          // Calculate the next occurrence for this specific day
          final nextOccurrence = _getNextDayOccurrence(
            scheduledDate.hour,
            scheduledDate.minute,
            day
          );
          
          final nextOccurrenceTZ = tz.TZDateTime.from(nextOccurrence, tz.local);
          
          debugPrint('Scheduling reminder for day $day at ${nextOccurrenceTZ.toString()}');
          
          await _notifications.zonedSchedule(
            dayId,
            reminder.title,
            reminder.notes.isNotEmpty ? reminder.notes : 'Time for your ${reminder.type.toLowerCase()} reminder',
            nextOccurrenceTZ,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        // For non-repeating reminders, schedule as normal
        final reminderId = reminder.id?.hashCode ?? _getUniqueId();
        debugPrint('Scheduling new reminder with ID: $reminderId');
        
        await _notifications.zonedSchedule(
          reminderId,
          reminder.title,
          reminder.notes.isNotEmpty ? reminder.notes : 'Time for your ${reminder.type.toLowerCase()} reminder',
          scheduledTZ,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Show immediate confirmation
      await _notifications.show(
        _getUniqueId(),
        'Reminder Set',
        'Your reminder "${reminder.title}" is set for ${DateFormat('h:mm a').format(scheduledDate)}',
        notificationDetails,
      );

      // Verify the scheduled notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      debugPrint('Total pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        debugPrint('Pending notification ID: ${notification.id}, Title: ${notification.title}');
      }

    } catch (e) {
      debugPrint('‼️ ERROR SCHEDULING NOTIFICATION: $e');
      debugPrint('Error stack trace: ${e.toString()}');
      // Show error notification to user
      await _notifications.show(
        _getUniqueId(),
        'Error Setting Reminder',
        'There was an error setting your reminder. Please try again.',
        notificationDetails,
      );
    }
  }

  // Cancel all notifications for a reminder
  static Future<void> cancelReminder(String? reminderId) async {
    if (reminderId != null) {
      await _notifications.cancel(reminderId.hashCode);
      
      if (_badgeCount > 0) {
        _badgeCount--;
        if (_badgeCount == 0) {
          FlutterAppBadger.removeBadge();
        } else {
          FlutterAppBadger.updateBadgeCount(_badgeCount);
        }
      }
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    FlutterAppBadger.removeBadge();
    _badgeCount = 0;
    debugPrint('All notifications cancelled');
  }

  // Find the next occurrence date for a repeating reminder
  static DateTime _findNextOccurrence(Reminder reminder, DateTime fromDate) {
    if (!reminder.isRepeating) return reminder.dateTime;

    DateTime candidateDate = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      reminder.dateTime.hour,
      reminder.dateTime.minute,
    );

    // If today's time has already passed, start from tomorrow
    if (candidateDate.isBefore(fromDate)) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    // Find the next day that matches the repeat pattern
    for (int i = 0; i < 7; i++) {
      // Get the day of week (1-7, where 1 is Monday)
      int dayOfWeek = candidateDate.weekday;
      
      // Check if this day is in the repeat days
      if (reminder.repeatDays.contains(dayOfWeek)) {
        return candidateDate;
      }
      
      // Move to next day
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    // Default to the original date if no match found
    return reminder.dateTime;
  }
  
  // Calculate the next occurrence of a specific day of week
  static DateTime _getNextDayOccurrence(int hour, int minute, int targetWeekday) {
    // Start with today
    DateTime now = DateTime.now();
    
    // Create a datetime with the target time for today
    DateTime candidate = DateTime(
      now.year, 
      now.month, 
      now.day, 
      hour, 
      minute
    );
    
    // If it's earlier today and today matches the target day, use today
    if (candidate.weekday == targetWeekday && candidate.isAfter(now)) {
      return candidate;
    }
    
    // Otherwise, find the next occurrence of the day
    int daysToAdd = (targetWeekday - now.weekday) % 7;
    if (daysToAdd == 0) {
      // If it's the same day but time has passed, go to next week
      daysToAdd = 7;
    }
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      hour,
      minute,
    );
  }
}