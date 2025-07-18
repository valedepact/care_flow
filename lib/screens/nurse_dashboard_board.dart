import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart'; // For date formatting

import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/models/appointment.dart'; // Import the Appointment model

import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage (for scheduling)
import 'package:care_flow/screens/add_appointment_screen.dart'; // Import the AddAppointmentScreen
import 'package:care_flow/screens/add_patient_screen.dart'; // Import the AddPatientScreen
import 'package:care_flow/screens/patient_profile_page.dart'; // Import the PatientProfilePage
import 'package:care_flow/screens/messaging_page.dart'; // Import the MessagingPage (ChatListPage)
import 'package:care_flow/screens/nurse_patient_list_screen.dart'; // Import NursePatientListScreen
import 'package:care_flow/screens/nurse_appointments_screen.dart'; // Import NurseAppointmentsScreen
import 'package:care_flow/screens/nurse_reports_screen.dart'; // Import NurseReportsScreen
import 'package:care_flow/screens/nurse_navigation_screen.dart'; // Import NurseNavigationScreen
import 'package:care_flow/screens/nurse_alerts_management_screen.dart'; // Import the new NurseAlertsManagementScreen
import 'package:care_flow/screens/role_router_screen.dart'; // Import RoleRouterScreen for logout navigation
import 'package:care_flow/screens/medical_records_page.dart'; // Corrected: Import MedicalRecordsPage
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Corrected: Import PatientPrescriptionsScreen

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _selectedIndex = 0;
  String _nurseName = 'Loading...';
  bool _isLoading = true;
  List<Patient> _patients = []; // List to store fetched patients
  List<Appointment> _upcomingVisits = []; // Changed to List<Appointment>

  @override
  void initState() {
    super.initState();
    _fetchNurseData();
    _fetchPatients();
    // _fetchUpcomingVisits() will be called after _fetchNurseData completes
  }

  Future<void> _fetchNurseData() async {
    final currentContext = context; // Capture context
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!currentContext.mounted) return; // Check mounted after await

        if (userDoc.exists) {
          setState(() {
            _nurseName = userDoc.get('fullName') ?? 'Caregiver';
            _isLoading = false;
          });
          await _fetchUpcomingVisits(currentUser.uid); // Fetch visits after nurse data is loaded
        } else {
          debugPrint('Nurse document not found for UID: ${currentUser.uid}');
          setState(() {
            _nurseName = 'Caregiver (Profile Incomplete)';
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching nurse data: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Error loading nurse data: $e')),
          );
          setState(() {
            _nurseName = 'Error Loading';
            _isLoading = false;
          });
        }
      }
    } else {
      if (currentContext.mounted) {
        Navigator.pushAndRemoveUntil(
          currentContext,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _fetchPatients() async {
    try {
      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance.collection('patients').get();

      if (!mounted) return; // Check mounted after await

      List<Patient> fetchedPatients = patientSnapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _patients = fetchedPatients;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
    }
  }

  Future<void> _fetchUpcomingVisits(String nurseId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('assignedToId', isEqualTo: nurseId) // Filter by current nurse's ID
          .where('dateTime', isGreaterThanOrEqualTo: DateTime.now()) // Only upcoming visits
          .orderBy('dateTime', descending: false) // Order by date ascending
          .limit(5) // Limit to a few upcoming visits for the dashboard card
          .get();

      if (!mounted) return; // Check mounted after await

      List<Appointment> fetchedVisits = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime visitDateTime = (data['dateTime'] as Timestamp).toDate();

        AppointmentStatus parsedStatus = AppointmentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
          orElse: () => AppointmentStatus.upcoming,
        );

        return Appointment(
          id: doc.id,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? 'Unknown Patient',
          type: data['type'] ?? 'General Consultation',
          dateTime: visitDateTime,
          location: data['location'] ?? 'N/A',
          status: parsedStatus,
          notes: data['notes'] ?? '',
          assignedToId: data['assignedToId'],
          assignedToName: data['assignedToName'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          statusColor: Appointment.getColorForStatus(parsedStatus),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _upcomingVisits = fetchedVisits;
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming visits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading upcoming visits: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (!currentContext.mounted) return; // Check mounted after await
      Navigator.pushAndRemoveUntil(
        currentContext,
        MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    final currentContext = context; // Capture context
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (currentContext) => const NursePatientListScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (currentContext) => const NurseAppointmentsScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (currentContext) => const NurseNavigationScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (currentContext) => const NurseReportsScreen()),
      );
    }
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
              debugPrint('Search button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              debugPrint('Notifications button pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Hello, $_nurseName!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Today, ${DateFormat('MMM d').format(DateTime.now())}', // Dynamic date
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Day at a Glance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _patientListCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _upcomingPatientsVisitsCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          '${_patients.length}',
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
                          '${_upcomingVisits.length}', // Dynamic today's visits
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
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    QuickActionButton(
                      label: 'Add Patient',
                      icon: Icons.person_add_rounded,
                      onPressed: () {
                        final currentContext = context; // Capture context
                        Navigator.push(
                          currentContext,
                          MaterialPageRoute(builder: (context) => const AddPatientScreen()),
                        ).then((_) {
                          if (currentContext.mounted) { // Check mounted
                            _fetchPatients();
                          }
                        });
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
                    QuickActionButton(
                      label: 'Manage Alerts',
                      icon: Icons.list_alt,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NurseAlertsManagementScreen()),
                        );
                        debugPrint('Manage Alerts pressed from Nurse Dashboard');
                      },
                      color: Colors.deepPurple,
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
            _patients.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No patients assigned yet.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length > 4 ? 4 : _patients.length,
              itemBuilder: (context, index) {
                final Patient patient = _patients[index];
                return InkWell(
                  onTap: () {
                    final currentContext = context; // Capture context
                    Navigator.push(
                      currentContext,
                      MaterialPageRoute(
                        builder: (context) => PatientProfilePage(
                          patientId: patient.id,
                          patientName: patient.name,
                        ),
                      ),
                    ).then((_) {
                      if (currentContext.mounted) { // Check mounted
                        _fetchPatients();
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Text(patient.name),
                        const Spacer(),
                        Text(patient.condition.isNotEmpty ? patient.condition : 'Stable'),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_patients.length > 4)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NursePatientListScreen()),
                    ).then((_) {
                      // No need for mounted check here as _fetchPatients itself has it.
                      _fetchPatients();
                    });
                    debugPrint('View All Patients pressed');
                  },
                  child: Text(
                    'View All Patients',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
            _upcomingVisits.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No upcoming visits today.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingVisits.length, // Display all fetched visits
              itemBuilder: (context, index) {
                final visit = _upcomingVisits[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Text(visit.patientName),
                      const SizedBox(width: 10),
                      Text(visit.location),
                      const Spacer(),
                      Text(DateFormat('h:mm a').format(visit.dateTime)),
                    ],
                  ),
                );
              },
            ),
            if (_upcomingVisits.isNotEmpty) // Show "View All" if there are any visits
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VisitSchedulePage()),
                    );
                    debugPrint('View All Visits pressed');
                  },
                  child: Text(
                    'View All Visits',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
