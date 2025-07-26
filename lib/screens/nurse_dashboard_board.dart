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
  int _selectedIndex = 0; // For BottomNavigationBar

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
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: color != null ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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

  void _onItemTapped(int index) {
    final currentContext = context; // Capture context
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on index
    switch (index) {
      case 0: // Home (Dashboard) - no navigation needed, already here
        break;
      case 1: // Patients
        Navigator.push(
          currentContext,
          MaterialPageRoute(builder: (context) => NursePatientListScreen(nurseId: _currentNurseId!)),
        );
        break;
      case 2: // Schedule (Appointments)
        Navigator.push(
          currentContext,
          MaterialPageRoute(builder: (context) => const NurseAppointmentsScreen()),
        );
        break;
      case 3: // Map (Navigation)
        Navigator.push(
          currentContext,
          MaterialPageRoute(builder: (context) => const NurseNavigationScreen()),
        );
        break;
      case 4: // Reports
        Navigator.push(
          currentContext,
          MaterialPageRoute(builder: (context) => const NurseReportsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        backgroundColor: Colors.blueAccent.withOpacity(0.9),
        elevation: 4,
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoadingDashboard
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Nurse Icon
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Icon(
                            Icons.local_hospital_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Welcome Message
                      Text(
                        'Welcome, Nurse $_nurseName!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent.shade700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Here's a quick overview of your day.",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Dashboard Cards
                      Wrap(
                        spacing: 32,
                        runSpacing: 32,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: 380,
                            child: _patientListCard(),
                          ),
                          SizedBox(
                            width: 380,
                            child: _upcomingPatientsVisitsCard(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Dashboard Buttons
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent.shade700,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildDashboardButton(
                            context,
                            icon: Icons.people_alt_rounded,
                            label: 'Patients',
                            onPressed: () => _onItemTapped(1),
                            color: Colors.blue.shade100,
                          ),
                          _buildDashboardButton(
                            context,
                            icon: Icons.calendar_month_rounded,
                            label: 'Schedule',
                            onPressed: () => _onItemTapped(2),
                            color: Colors.green.shade100,
                          ),
                          _buildDashboardButton(
                            context,
                            icon: Icons.navigation_rounded,
                            label: 'Navigation',
                            onPressed: () => _onItemTapped(3),
                            color: Colors.orange.shade100,
                          ),
                          _buildDashboardButton(
                            context,
                            icon: Icons.analytics_rounded,
                            label: 'Reports',
                            onPressed: () => _onItemTapped(4),
                            color: Colors.purple.shade100,
                          ),
                          _buildDashboardButton(
                            context,
                            icon: Icons.notifications_active_rounded,
                            label: 'Alerts',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NurseAlertsManagementScreen(),
                                ),
                              );
                            },
                            color: Colors.red.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
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
