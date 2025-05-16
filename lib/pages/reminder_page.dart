import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:water_quality_analysis/class/notification.dart';
import 'package:water_quality_analysis/class/reminder.dart';
import 'package:water_quality_analysis/class/reminder_repository.dart';
import 'package:water_quality_analysis/main.dart';
import 'package:water_quality_analysis/pages/add_reminder_page.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({Key? key}) : super(key: key);

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> with WidgetsBindingObserver {
  final ReminderRepository _reminderRepository = ReminderRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Initialize notifications when app starts
  Future _initializeNotifications() async {
    await NotificationService.initialize();
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reminders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please sign in to view reminders',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/sign_in');
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stay on track with your water health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set reminders for water intake, filter replacements, and quality checks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Reminder>>(
                  stream: _reminderRepository.getReminders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      _errorMessage = 'Error loading reminders: ${snapshot.error}';
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 72,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading reminders',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage ?? 'Please try again later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _retryLoading,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    List<Reminder> reminders = snapshot.data ?? [];
                    
                    if (reminders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 72,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reminders yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add a reminder',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        return _buildReminderCard(reminders[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      floatingActionButton: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6366F1),
              onPressed: () => _navigateToAddReminder(context),
              label: const Text(
                'Add Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    Color cardColor;
    IconData typeIcon;
    
    // Set color and icon based on reminder type
    switch (reminder.type) {
      case 'Water Intake':
        cardColor = Colors.blue;
        typeIcon = Icons.water_drop;
        break;
      case 'Filter Replacement':
        cardColor = Colors.indigo;
        typeIcon = Icons.filter_alt;
        break;
      case 'Quality Check':
        cardColor = Colors.purple;
        typeIcon = Icons.science;
        break;
      default:
        cardColor = Colors.teal;
        typeIcon = Icons.notifications;
    }

    // Check if this is a repeating reminder card (has _ in the ID)
    bool isRepeatingCard = reminder.id!.contains('_');
    
    // Get the day name for repeating reminders
    String dayName = '';
    if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
      List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dayName = dayNames[reminder.repeatDays[0] - 1];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditReminder(context, reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  typeIcon,
                  color: cardColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.formattedTime,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    if (isRepeatingCard)
                      Text(
                        'Every $dayName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    else if (reminder.isRepeating)
                      Text(
                        'Repeats: ${reminder.repeatDescription}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (reminder.notes.isNotEmpty)
                      Text(
                        reminder.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _deleteReminder(reminder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderPage(),
      ),
    );
  }

  void _navigateToEditReminder(BuildContext context, Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderPage(reminder: reminder),
      ),
    );
  }

  void _deleteReminder(Reminder reminder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                if (reminder.id != null) {
                  try {
                    // Check if this is a repeating reminder card (has _ in the ID)
                    if (reminder.id!.contains('_')) {
                      // Extract the base reminder ID and the day
                      final parts = reminder.id!.split('_');
                      final baseId = parts[0];
                      final day = int.parse(parts[1]);
                      
                      // Get the original reminder
                      final doc = await _reminderRepository.remindersCollection.doc(baseId).get();
                      if (doc.exists) {
                        final data = doc.data() as Map<String, dynamic>;
                        List<dynamic> repeatDays = List<int>.from(data['repeatDays'] ?? []);
                        
                        // Remove the specific day from repeatDays
                        repeatDays.remove(day);
                        
                        // Update the reminder in Firestore
                        await _reminderRepository.remindersCollection.doc(baseId).update({
                          'repeatDays': repeatDays
                        });
                        
                        // Cancel the notification for this specific day
                        await NotificationService.cancelReminder(reminder.id);
                      }
                    } else {
                      // For non-repeating reminders, delete as normal
                      await _reminderRepository.deleteReminder(reminder.id!);
                      await NotificationService.cancelReminder(reminder.id);
                    }
                    
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting reminder: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}