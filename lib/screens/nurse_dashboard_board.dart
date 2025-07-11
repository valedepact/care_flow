import 'package:flutter/material.dart';
import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage
import 'package:care_flow/screens/add_appointment_screen.dart'; // Import the AddAppointmentScreen
import 'package:care_flow/screens/add_patient_screen.dart'; // Import the AddPatientScreen
import 'package:care_flow/screens/patient_profile_page.dart'; // Import the PatientProfilePage
import 'package:care_flow/screens/messaging_page.dart'; // Import the MessagingPage (ChatListPage)

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Optional: Add specific navigation logic for bottom navigation bar items if needed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAREGIVER DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              print('Search button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              print('Notifications button pressed');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Welcome section
                Text(
                  'Hello, Caregiver!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Today, March 12',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 24),
                // Overview section
                Text(
                  'Your Day at a Glance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Patient list and upcoming Patient visits row
                Row(
                  children: [
                    Expanded(
                      child: _patientListCard(), // This will now be tappable
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _upcomingPatientsVisitsCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Patient Activity Log and Alerts/Notifications row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total Patients',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '25',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Today\'s Visits',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '10',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Schedule',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VisitSchedulePage()),
                        );
                        print('View All Schedule button pressed');
                      },
                      child: Text(
                        'View All',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Actions Section
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0, // horizontal spacing
                  runSpacing: 12.0, // vertical spacing
                  alignment: WrapAlignment.center,
                  children: [
                    QuickActionButton(
                      label: 'Add Patient',
                      icon: Icons.person_add_rounded,
                      onPressed: () {
                        // Navigate to the AddPatientScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddPatientScreen()),
                        );
                        print('Add Patient button pressed');
                      },
                      color: Colors.purple,
                    ),
                    QuickActionButton(
                      label: 'New Appointment',
                      icon: Icons.calendar_month, // Changed icon to be more appointment-specific
                      onPressed: () {
                        // Navigate to the AddAppointmentScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddAppointmentScreen()),
                        );
                        print('New appointment button pressed');
                      },
                      color: Colors.orange,
                    ),
                    QuickActionButton(
                      label: 'Generate Report',
                      icon: Icons.description, // Changed icon
                      onPressed: () {
                        print('Add report button pressed');
                      },
                      color: Colors.teal,
                    ),
                    QuickActionButton(
                      label: 'Start Navigation',
                      icon: Icons.navigation, // Changed icon
                      onPressed: () {
                        print('Navigation button pressed');
                      },
                      color: Colors.redAccent,
                    ),
                    // Button for scheduling reminders/alerts
                    QuickActionButton(
                      label: 'Schedule Reminder',
                      icon: Icons.add_alarm,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AlertsPage()),
                        );
                        print('Schedule Reminder button pressed');
                      },
                      color: Colors.blueGrey, // A distinct color
                    ),
                    // New: Messages Quick Action Button for Nurse Dashboard
                    QuickActionButton(
                      label: 'Messages',
                      icon: Icons.message,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatListPage()),
                        );
                        print('Messages button pressed from Nurse Dashboard');
                      },
                      color: Colors.indigo, // A distinct color for messages
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  // Patient List Card
  Widget _patientListCard() {
    // Dummy patient names for demonstration
    final List<String> patients = ['John Kelly', 'Anna Davis', 'Greg Teri', 'Walter Reed'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATIENT LIST',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1.5),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patients.length, // Use actual patient list length
              itemBuilder: (context, index) {
                final String patientName = patients[index];
                return InkWell( // Make the entire row tappable
                  onTap: () {
                    // Navigate to PatientProfilePage, passing the patient's name
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientProfilePage(patientName: patientName),
                      ),
                    );
                    print('Tapped on patient: $patientName');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding to list tile
                    child: Row(
                      children: [
                        Text(patientName),
                        const Spacer(),
                        const Text('Active'), // Placeholder Status
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Upcoming Patients Visits Card
  Widget _upcomingPatientsVisitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPCOMING PATIENT VISITS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1.5),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10, // Replace with actual visits length
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Text('Patient Name $index'),
                    const SizedBox(width: 10),
                    const Text('Location'), // Replace with actual location, i think it will b google maps
                    const Spacer(),
                    const Text('9:00 AM'), // Replace with actual time
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white, // Ensure text is white for better contrast on colored buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
