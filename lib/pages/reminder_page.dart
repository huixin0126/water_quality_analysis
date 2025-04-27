import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReminderTypeCard(
              context,
              title: 'Water Intake Reminder',
              icon: Icons.water_drop_outlined,
              description: 'Set reminders to drink water throughout the day',
              route: '/water_intake_reminder',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildReminderTypeCard(
              context,
              title: 'Filter Replacement Reminder',
              icon: Icons.filter_alt_outlined,
              description: 'Get notified when it\'s time to replace your filter',
              route: '/set_reminder',
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            _buildReminderTypeCard(
              context,
              title: 'Water Quality Check Reminder',
              icon: Icons.science_outlined,
              description: 'Regular reminders to check your water quality',
              route: '/set_reminder',
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            
            // Tips Section
            const Text(
              'Water Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.lightbulb_outline,
              title: 'Keep Hydrated',
              content: 'Try to drink at least 8 glasses of water each day for optimal health.',
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              icon: Icons.eco_outlined,
              title: 'Water Conservation',
              content: 'Turn off the tap while brushing teeth to save up to 8 gallons of water daily.',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              icon: Icons.whatshot_outlined,
              title: 'Temperature Matters',
              content: 'Room temperature water is better for digestion than cold water.',
              color: Colors.red,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildReminderTypeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}