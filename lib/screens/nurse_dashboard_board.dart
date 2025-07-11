import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart'; // For date formatting
// Removed: import 'package:flutter/foundation.dart'; // debugPrint is now covered by material.dart

import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:care_flow/screens/alert_page.dart';
import 'package:care_flow/screens/add_appointment_screen.dart';
import 'package:care_flow/screens/add_patient_screen.dart';
import 'package:care_flow/screens/messaging_page.dart';
import 'package:care_flow/screens/nurse_patient_list_screen.dart';
import 'package:care_flow/screens/nurse_appointments_screen.dart';
import 'package:care_flow/screens/nurse_reports_screen.dart';
import 'package:care_flow/screens/nurse_navigation_screen.dart';
import 'package:care_flow/models/patient.dart'; // Import Patient model (contains Appointment)
import 'package:care_flow/screens/patient_profile_page.dart'; // Import PatientProfilePage

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _selectedIndex = 0;
  User? _currentUser;
  String? _currentUserName;
  String? _currentUserRole; // This variable is now used

  List<Appointment> _upcomingVisits = [];
  bool _isLoadingVisits = true;
  String _visitsErrorMessage = '';

  List<Patient> _recentPatients = [];
  bool _isLoadingPatients = true;
  String _patientsErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchDashboardData();
  }

  Future<void> _initializeUserAndFetchDashboardData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      debugPrint('User not logged in. Cannot fetch dashboard data.');
      // Optionally navigate to login or show a message
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Caregiver';
        _currentUserRole = userDoc.get('role'); // Get the role
      } else {
        _currentUserName = 'Caregiver';
        _currentUserRole = 'Unknown Role';
      }
      // Fetch data for the cards
      await _fetchUpcomingVisits();
      await _fetchRecentPatients();
    } catch (e) {
      debugPrint('Error initializing user or fetching dashboard data: $e');
      setState(() {
        _visitsErrorMessage = 'Failed to load dashboard data: $e';
        _isLoadingVisits = false;
        _patientsErrorMessage = 'Failed to load dashboard data: $e';
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _fetchUpcomingVisits() async {
    setState(() {
      _isLoadingVisits = true;
      _visitsErrorMessage = '';
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('assignedToId', isEqualTo: _currentUser!.uid)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now()) // Only future appointments
          .orderBy('dateTime', descending: false)
          .limit(3) // Limit to a few upcoming visits for the dashboard glance
          .get();

      List<Appointment> fetchedVisits = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();

        return Appointment(
          id: doc.id,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? 'Unknown Patient',
          type: data['type'] ?? 'General Consultation', // Ensure 'type' is retrieved
          dateTime: appointmentDateTime,
          location: data['location'] ?? 'N/A',
          status: AppointmentStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
            orElse: () => AppointmentStatus.upcoming,
          ),
          notes: data['notes'] ?? '',
          statusColor: Appointment.getColorForStatus(AppointmentStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
            orElse: () => AppointmentStatus.upcoming,
          )),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _upcomingVisits = fetchedVisits;
          _isLoadingVisits = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming visits: $e');
      if (mounted) {
        setState(() {
          _visitsErrorMessage = 'Error loading upcoming visits: $e';
          _isLoadingVisits = false;
        });
      }
    }
  }

  Future<void> _fetchRecentPatients() async {
    setState(() {
      _isLoadingPatients = true;
      _patientsErrorMessage = '';
    });
    try {
      // For simplicity, fetching all patients for now.
      // In a real app, you might filter by patients assigned to the current nurse.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .orderBy('createdAt', descending: true) // Assuming a 'createdAt' field
          .limit(4) // Limit to a few recent patients for the dashboard glance
          .get();

      List<Patient> fetchedPatients = snapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _recentPatients = fetchedPatients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent patients: $e');
      if (mounted) {
        setState(() {
          _patientsErrorMessage = 'Error loading recent patients: $e';
          _isLoadingPatients = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on bottom navigation bar item
    if (index == 1) { // 'Patients' tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NursePatientListScreen()),
      );
    } else if (index == 2) { // 'Schedule' tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NurseAppointmentsScreen()),
      );
    } else if (index == 3) { // 'Map' tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NurseNavigationScreen()),
      );
    } else if (index == 4) { // 'Reports' tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NurseReportsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CAREGIVER DASHBOARD (${_currentUserName ?? "Caregiver"} - ${_currentUserRole ?? "Role Unknown"})'), // Using _currentUserName and _currentUserRole
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              debugPrint('Search button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              debugPrint('Notifications button pressed');
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
                  'Hello, ${_currentUserName ?? 'Caregiver'}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Today, ${DateFormat('MMM d').format(DateTime.now())}',
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
                      child: _buildDashboardInfoCard(
                        context,
                        title: 'RECENT PATIENTS',
                        content: _isLoadingPatients
                            ? 'Loading patients...'
                            : _patientsErrorMessage.isNotEmpty
                            ? _patientsErrorMessage
                            : _recentPatients.isEmpty
                            ? 'No patients found.'
                            : '', // Content will be built by ListView
                        icon: Icons.group,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NursePatientListScreen()),
                          );
                          debugPrint('Navigating to Nurse Patient List Screen');
                        },
                        child: _isLoadingPatients
                            ? const Center(child: CircularProgressIndicator())
                            : _patientsErrorMessage.isNotEmpty
                            ? Center(child: Text(_patientsErrorMessage, style: const TextStyle(color: Colors.red)))
                            : _recentPatients.isEmpty
                            ? const Center(child: Text('No recent patients.'))
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _recentPatients[index];
                            return InkWell( // Make the entire row tappable
                              onTap: () {
                                // Navigate to PatientProfilePage, passing the patient ID and Name
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientProfilePage(
                                      patientId: patient.id,
                                      patientName: patient.name,
                                    ),
                                  ),
                                );
                                debugPrint('Tapped on patient: ${patient.name}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        patient.name,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      patient.condition.isNotEmpty ? patient.condition : 'N/A',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                          '25', // This should be dynamic from Firestore
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
                          '${_upcomingVisits.length}', // Dynamic count of today's visits
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
                        debugPrint('View All Schedule button pressed');
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddPatientScreen()),
                        );
                        debugPrint('Add Patient button pressed');
                      },
                      color: Colors.purple,
                    ),
                    QuickActionButton(
                      label: 'New Appointment',
                      icon: Icons.calendar_month,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddAppointmentScreen()),
                        );
                        debugPrint('New appointment button pressed');
                      },
                      color: Colors.orange,
                    ),
                    QuickActionButton(
                      label: 'Generate Report',
                      icon: Icons.description,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NurseReportsScreen()),
                        );
                        debugPrint('Generate Report button pressed - Navigating to reports screen');
                      },
                      color: Colors.teal,
                    ),
                    QuickActionButton(
                      label: 'Start Navigation',
                      icon: Icons.navigation,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NurseNavigationScreen()),
                        );
                        debugPrint('Navigation button pressed - Navigating to navigation screen');
                      },
                      color: Colors.redAccent,
                    ),
                    QuickActionButton(
                      label: 'Schedule Reminder',
                      icon: Icons.add_alarm,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AlertsPage()),
                        );
                        debugPrint('Schedule Reminder button pressed');
                      },
                      color: Colors.blueGrey,
                    ),
                    QuickActionButton(
                      label: 'Messages',
                      icon: Icons.message,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatListPage()),
                        );
                        debugPrint('Messages button pressed from Nurse Dashboard');
                      },
                      color: Colors.indigo,
                    ),
                    QuickActionButton(
                      label: 'My Appointments',
                      icon: Icons.calendar_today,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NurseAppointmentsScreen()),
                        );
                        debugPrint('My Appointments button pressed from Nurse Dashboard');
                      },
                      color: Colors.green,
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

  // Helper for general info cards on dashboard
  Widget _buildDashboardInfoCard(BuildContext context, {
    required String title,
    String? content, // Made optional as child widget will provide content
    required IconData icon,
    required VoidCallback onTap,
    Widget? child, // Added optional child to allow custom content
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(thickness: 1.5, height: 20),
              if (child != null)
                Expanded(child: child) // Use the provided child for content
              else if (content != null && content.isNotEmpty)
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Upcoming Patients Visits Card (now fetches real data)
  Widget _upcomingPatientsVisitsCard() {
    return _buildDashboardInfoCard(
      context,
      title: 'UPCOMING VISITS',
      content: _isLoadingVisits
          ? 'Loading visits...'
          : _visitsErrorMessage.isNotEmpty
          ? _visitsErrorMessage
          : _upcomingVisits.isEmpty
          ? 'No upcoming visits.'
          : '', // Content will be built by ListView
      icon: Icons.calendar_today,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NurseAppointmentsScreen()), // Navigate to full appointments
        );
        debugPrint('Navigating to Nurse Appointments Screen from Upcoming Visits Card');
      },
      child: _isLoadingVisits
          ? const Center(child: CircularProgressIndicator())
          : _visitsErrorMessage.isNotEmpty
          ? Center(child: Text(_visitsErrorMessage, style: const TextStyle(color: Colors.red)))
          : _upcomingVisits.isEmpty
          ? const Center(child: Text('No upcoming visits.'))
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _upcomingVisits.length,
        itemBuilder: (context, index) {
          final visit = _upcomingVisits[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    visit.patientName,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(visit.dateTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
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
