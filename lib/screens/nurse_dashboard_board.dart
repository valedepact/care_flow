import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/screens/role_router_screen.dart'; // For logout navigation
import 'package:care_flow/screens/nurse_patient_list_screen.dart'; // For My Patients
import 'package:care_flow/screens/nurse_appointments_screen.dart'; // For Nurse Appointments
import 'package:care_flow/screens/nurse_alerts_management_screen.dart'; // Import the new NurseAlertsManagementScreen
import 'package:care_flow/screens/nurse_reports_screen.dart'; // Import NurseReportsScreen
import 'package:care_flow/screens/add_patient_screen.dart'; // For adding/claiming patients
import 'package:care_flow/screens/visit_schedule_page.dart'; // For nurse's visit schedule
import 'package:care_flow/screens/patient_profile_page.dart'; // Import the PatientProfilePage
import 'package:care_flow/screens/appointment_details_page.dart'; // Import AppointmentDetailsPage
import 'package:care_flow/screens/messaging_page.dart'; // For messaging (ChatListPage)
import 'package:care_flow/screens/nurse_navigation_screen.dart'; // For Nurse Navigation

// IMPORTANT: Ensure these model imports are correct and the files exist and are valid.
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/models/appointment.dart'; // Import the Appointment model

import 'package:intl/intl.dart'; // For date formatting
import 'package:hive/hive.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  String _nurseName = 'Loading...';
  String? _currentNurseId;
  bool _isLoadingDashboard = true; // Combined loading state for the whole dashboard
  List<Patient> _patients = []; // List of patients assigned to this nurse
  List<Appointment> _upcomingVisits = []; // List of upcoming visits for this nurse
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    // Dashboard main content
    SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome,  $_nurseName!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _patientListCard(),
          const SizedBox(height: 20),
          _upcomingPatientsVisitsCard(),
        ],
      ),
    ),
    NursePatientListScreen(nurseId: _currentNurseId ?? ''),
    NurseAppointmentsScreen(),
    NurseNavigationScreen(),
    NurseReportsScreen(),
    NurseAlertsManagementScreen(),
    ChatListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardPatients();
  }

  Future<void> _loadDashboardPatients() async {
    final currentContext = context;
    setState(() {
      _isLoadingDashboard = true; // Start loading for the entire dashboard
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (currentContext.mounted) {
        Navigator.pushReplacement(
          currentContext,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
        );
      }
      return;
    }

    _currentNurseId = currentUser.uid;

    // 1. Load from Hive first (fast, offline)
    var patientBox = Hive.box<Patient>('patients');
    setState(() {
      _patients = patientBox.values.toList().take(5).toList();
      _isLoadingDashboard = false;
    });

    try {
      // 1. Fetch Nurse Data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentNurseId)
          .get();

      if (!currentContext.mounted) return; // Check mounted after await

      if (userDoc.exists) {
        _nurseName = userDoc.get('fullName') ?? 'Nurse';
      } else {
        debugPrint('Nurse document not found for UID: $_currentNurseId');
        _nurseName = 'Nurse (Profile Incomplete)';
      }

      // 2. Fetch Patients assigned to this Nurse
      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: _currentNurseId)
          .orderBy('name', descending: false)
          .limit(5) // Limit to a few recent patients for the dashboard card
          .get();

      if (!currentContext.mounted) return;

      _patients = patientSnapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Update Hive with latest patients (replace all for simplicity)
      await patientBox.clear();
      await patientBox.addAll(_patients);

      // 3. Fetch Upcoming Visits for this Nurse
      QuerySnapshot visitSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('assignedToId', isEqualTo: _currentNurseId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now()) // Only upcoming visits
          .orderBy('dateTime', descending: false) // Order by date ascending
          .limit(5) // Limit to a few upcoming visits for the dashboard card
          .get();

      if (!currentContext.mounted) return;

      _upcomingVisits = visitSnapshot.docs.map((doc) {
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
        );
      }).toList();

    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
      // Optionally clear data or show specific error messages
      _nurseName = 'Error Loading';
      _patients = [];
      _upcomingVisits = [];
    } finally {
      if (currentContext.mounted) {
        setState(() {
          _isLoadingDashboard = false; // End loading for the entire dashboard
        });
      }
    }
  }

  Future<void> _logout() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoadingDashboard = true; // Show loading while logging out
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (!currentContext.mounted) return;
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
          _isLoadingDashboard = false;
        });
      }
    }
  }

  // Helper method for dashboard buttons
  Widget _buildDashboardButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 110, // Smaller width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: color != null ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // More compact
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // More rounded
          ),
          elevation: 4,
          shadowColor: Colors.black12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22), // Smaller icon
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600), // Smaller, bolder
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display a card with recent patients
  Widget _patientListCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Patients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 15),
            _patients.isEmpty
                ? const Center(
              child: Text('You have not claimed any patients yet.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length, // Display all fetched patients (up to limit)
              itemBuilder: (context, index) {
                final Patient patient = _patients[index];
                return InkWell(
                  onTap: () {
                    if (patient.id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientProfilePage(
                            patientId: patient.id,
                            patientName: patient.name,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient ID not available. Cannot view profile.')),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          patient.condition.isNotEmpty ? patient.condition : 'Stable',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_currentNurseId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NursePatientListScreen(
                          nurseId: _currentNurseId!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nurse ID not available. Cannot view full list.')),
                    );
                  }
                  debugPrint('View All Patients pressed - Navigating to NursePatientListScreen');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
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
    );
  }

  // Upcoming Patients Visits Card
  Widget _upcomingPatientsVisitsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Visits', // Changed title to be more general
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 15),
            _upcomingVisits.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No upcoming visits scheduled.'),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingVisits.length, // Display all fetched visits
              itemBuilder: (context, index) {
                final visit = _upcomingVisits[index];
                return InkWell(
                  onTap: () {
                    // Navigate to AppointmentDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsPage(appointment: visit),
                      ),
                    );
                    debugPrint('View details for visit: ${visit.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${visit.patientName} (${visit.type})', // Show patient name and type
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a').format(visit.dateTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VisitSchedulePage()),
                  );
                  debugPrint('View All Visits pressed');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation_rounded),
            label: 'Navigation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
