import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/appointment.dart'; // Corrected: Import the Appointment model

class AppointmentDetailsPage extends StatelessWidget {
  final Appointment appointment; // Expect to receive an Appointment object

  const AppointmentDetailsPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Title/Patient Name
            Text(
              'Appointment for ${appointment.patientName}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Status Badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Appointment.getColorForStatus(appointment.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.status.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16), // Added space

            // NEW: Display time remaining or overdue status prominently
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appointment.isOverdue
                    ? 'Status: Overdue'
                    : 'Time Remaining: ${appointment.getTimeRemainingString()}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: appointment.isOverdue ? Colors.red : Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),


            // Details Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, Icons.calendar_today, 'Date', DateFormat('EEEE, MMMM d, y').format(appointment.dateTime)),
                    _buildDetailRow(context, Icons.access_time, 'Time', DateFormat('h:mm a').format(appointment.dateTime)),
                    _buildDetailRow(context, Icons.location_on, 'Location', appointment.location),
                    _buildDetailRow(context, Icons.person, 'Patient ID', appointment.patientId),
                    // Display assignedToName if available
                    if (appointment.assignedToName != null && appointment.assignedToName!.isNotEmpty)
                      _buildDetailRow(context, Icons.badge, 'Assigned To', appointment.assignedToName!),
                    if (appointment.notes.isNotEmpty)
                      _buildDetailRow(context, Icons.notes, 'Notes', appointment.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons (Conditional based on status/role)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (appointment.status == AppointmentStatus.upcoming)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate reschedule
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reschedule functionality (dummy)')),
                        );
                        debugPrint('Reschedule appointment ${appointment.id}');
                      },
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Reschedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                if (appointment.status == AppointmentStatus.upcoming)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate cancel
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cancel functionality (dummy)')),
                        );
                        debugPrint('Cancel appointment ${appointment.id}');
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (appointment.status == AppointmentStatus.upcoming) // Only show mark completed for upcoming
                  const SizedBox(width: 16),
                if (appointment.status == AppointmentStatus.upcoming)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate mark as completed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mark as completed functionality (dummy)')),
                        );
                        debugPrint('Mark appointment ${appointment.id} as completed');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // You could add more sections here, e.g., related tasks, patient history summary
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
