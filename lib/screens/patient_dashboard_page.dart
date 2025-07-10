import 'package:flutter/material.dart';
import 'package:care_flow/screens/emergency_alerts_page.dart'; // Import the EmergencyAlertsPage
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        backgroundColor: Colors.blueAccent, // A distinct color for the patient dashboard
        elevation: 4, // Add a subtle shadow
      ),
      body: Center(
        child: SingleChildScrollView( // Added SingleChildScrollView for responsiveness
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Patient Icon
              Icon(
                Icons.person_outline,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),

              // Welcome Message
              Text(
                'Welcome, Patient!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle/Description
              Text(
                'Here you can manage your appointments, view medical records, and communicate with your care team.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),

              // Quick Actions/Navigation Buttons
              Wrap(
                spacing: 16.0, // Horizontal spacing
                runSpacing: 16.0, // Vertical spacing
                alignment: WrapAlignment.center,
                children: [
                  _buildDashboardButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'My Appointments',
                    onPressed: () {
                      // Navigate to appointments page
                      print('My Appointments pressed');
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.folder_open,
                    label: 'Medical Records',
                    onPressed: () {
                      // Navigate to medical records page
                      print('Medical Records pressed');
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.message,
                    label: 'Messages',
                    onPressed: () {
                      // Navigate to messages page
                      print('Messages pressed');
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.medication,
                    label: 'Prescriptions',
                    onPressed: () {
                      // Navigate to prescriptions page
                      print('Prescriptions pressed');
                    },
                  ),
                  // New Button: Emergency Alert
                  _buildDashboardButton(
                    context,
                    icon: Icons.notifications_active,
                    label: 'Emergency Alert',
                    onPressed: () {
                      // Navigate to Emergency Alerts Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyAlertsPage()),
                      );
                      print('Emergency Alert pressed');
                    },
                    color: Colors.red.shade700, // Make it stand out
                  ),
                  // New Button: Set Personal Reminder
                  _buildDashboardButton(
                    context,
                    icon: Icons.add_alarm,
                    label: 'Set Reminder',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AlertsPage()),
                      );
                      print('Set Reminder pressed from Patient Dashboard');
                    },
                    color: Colors.teal, // A distinct color
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Placeholder for recent activity or next appointment
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Appointment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.grey, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Dr. Smith - Cardiology',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'July 15, 2025 at 10:00 AM',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print('View Appointment Details pressed');
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for dashboard buttons
  Widget _buildDashboardButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color, // Added optional color parameter
  }) {
    return SizedBox(
      width: 150, // Fixed width for consistent button size
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.surfaceVariant, // Use provided color or default
          foregroundColor: color != null ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant, // Adjust foreground color based on background
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
