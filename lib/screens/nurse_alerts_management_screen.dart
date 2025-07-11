import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class NurseAlertsManagementScreen extends StatefulWidget {
  const NurseAlertsManagementScreen({super.key});

  @override
  State<NurseAlertsManagementScreen> createState() => _NurseAlertsManagementScreenState();
}

class _NurseAlertsManagementScreenState extends State<NurseAlertsManagementScreen> {
  // Dummy list of alerts/reminders for demonstration.
  // In a real application, these would be fetched from a backend,
  // filtered by alerts created by or relevant to the current nurse.
  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'alert_001',
      'title': 'Medication Reminder',
      'description': 'Remind Patient John to take hypertension medication.',
      'dateTime': DateTime.now().add(const Duration(hours: 2)),
      'patientName': 'Patient John',
      'status': 'Pending',
      'type': 'Medication',
    },
    {
      'id': 'alert_002',
      'title': 'Follow-up Call',
      'description': 'Call Anna Davis to check on wound healing progress.',
      'dateTime': DateTime.now().add(const Duration(days: 1)),
      'patientName': 'Anna Davis',
      'status': 'Pending',
      'type': 'Call',
    },
    {
      'id': 'alert_003',
      'title': 'Supply Restock Alert',
      'description': 'Order more sterile gloves for clinic.',
      'dateTime': DateTime.now().subtract(const Duration(days: 3)),
      'patientName': 'N/A', // Not patient-specific
      'status': 'Completed',
      'type': 'Supplies',
    },
    {
      'id': 'alert_004',
      'title': 'Appointment Confirmation',
      'description': 'Confirm tomorrow\'s appointment with Walter Reed.',
      'dateTime': DateTime.now().add(const Duration(hours: 10)),
      'patientName': 'Walter Reed',
      'status': 'Pending',
      'type': 'Appointment',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Sort alerts by date and time (upcoming first)
    _alerts.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alerts & Reminders'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _alerts.isEmpty
          ? const Center(
        child: Text('You have no alerts or reminders set.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final bool isCompleted = alert['status'] == 'Completed';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isCompleted ? Colors.grey[200] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert['title']!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey[600] : Theme.of(context).colorScheme.primary,
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alert['status']!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For: ${alert['patientName'] == 'N/A' ? 'Self' : alert['patientName']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Type: ${alert['type']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Time: ${DateFormat('MMM d, yyyy - h:mm a').format(alert['dateTime'])}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['description']!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: isCompleted ? FontStyle.italic : FontStyle.normal,
                      color: isCompleted ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCompleted)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                final indexToUpdate = _alerts.indexWhere((element) => element['id'] == alert['id']);
                                if (indexToUpdate != -1) {
                                  _alerts[indexToUpdate]['status'] = 'Completed';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Alert "${alert['title']}" marked as completed!')),
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Simulate deleting the alert
                            setState(() {
                              _alerts.removeWhere((element) => element['id'] == alert['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Alert "${alert['title']}" deleted.')),
                              );
                            });
                            print('Deleted alert: ${alert['id']}');
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
