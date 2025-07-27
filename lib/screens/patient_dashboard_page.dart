import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/appointment.dart'; // Import the Appointment model
import 'package:care_flow/screens/emergency_alerts_page.dart';
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage (for scheduling)
import 'package:care_flow/screens/my_alerts_screen.dart'; // Import the new MyAlertsScreen (for viewing)
import 'package:care_flow/screens/role_router_screen.dart'; // Import RoleRouterScreen for logout navigation
import 'package:care_flow/screens/my_appointments_page.dart'; // Import MyAppointmentsPage
import 'package:care_flow/screens/medical_records_page.dart'; // Corrected: Import MedicalRecordsPage
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Import PatientPrescriptionsScreen
import 'package:care_flow/screens/patient_notes_screen.dart'; // Corrected: Import PatientNotesScreen
import 'package:care_flow/screens/messaging_page.dart'; // Import the MessagingPage (ChatListPage)
import 'package:care_flow/screens/appointment_details_page.dart'; // Import AppointmentDetailsPage
import 'package:care_flow/screens/patient_profile_page.dart'; // NEW: Import PatientProfilePage

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  String _patientName = 'Loading...';
  String _patientId = '';
  bool _isLoadingUserData = true; // Separate loading for user data

  Appointment? _upcomingAppointment; // To store the fetched upcoming appointment
  bool _isLoadingUpcomingAppointment = true;
  String _upcomingAppointmentErrorMessage = '';

  int _selectedIndex = 0;

  List<Widget> get _pages => [
    // Dashboard main content
    SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome, 24_patientName!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Here you can manage your appointments, view medical records, and communicate with your care team.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 40),
          // You can add more dashboard summary widgets here if needed
        ],
      ),
    ),
    MyAppointmentsPage(),
    MedicalRecordsPage(patientId: _patientId, patientName: _patientName),
    ChatListPage(),
    PatientPrescriptionsScreen(patientId: _patientId, patientName: _patientName),
    PatientNotesScreen(patientId: _patientId, patientName: _patientName),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPatientDataAndUpcomingAppointment();
  }

  Future<void> _fetchPatientDataAndUpcomingAppointment() async {
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
            _patientName = userDoc.get('fullName') ?? 'Patient';
            _patientId = currentUser.uid; // Use UID as patient ID for now
            _isLoadingUserData = false;
          });
        } else {
          debugPrint('Patient document not found for UID: ${currentUser.uid}');
          setState(() {
            _patientName = 'Patient (Profile Incomplete)';
            _patientId = currentUser.uid;
            _isLoadingUserData = false;
          });
        }
        await _fetchUpcomingAppointment(currentUser.uid); // Fetch upcoming appointment
      } catch (e) {
        debugPrint('Error fetching patient data: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Error loading patient data: $e')),
          );
          setState(() {
            _patientName = 'Error Loading';
            _isLoadingUserData = false;
            _upcomingAppointmentErrorMessage = 'Error loading appointments: $e';
            _isLoadingUpcomingAppointment = false;
          });
        }
      }
    } else {
      // No user logged in, navigate back to login
      if (currentContext.mounted) {
        // This navigation should ideally be handled by RoleRouterScreen
        // if this page is only reachable after login.
        // For now, keeping it here for immediate feedback.
        Navigator.pushReplacement(
          currentContext,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
        );
      }
    }
  }

  Future<void> _fetchUpcomingAppointment(String patientId) async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoadingUpcomingAppointment = true;
      _upcomingAppointmentErrorMessage = '';
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now()) // Only future appointments
          .orderBy('dateTime', descending: false) // Get the soonest one
          .limit(1)
          .get();

      if (!currentContext.mounted) return; // Check mounted after await

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = snapshot.docs.first.data() as Map<String, dynamic>;

        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();
        AppointmentStatus parsedStatus = AppointmentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
          orElse: () => AppointmentStatus.upcoming,
        );

        setState(() {
          _upcomingAppointment = Appointment(
            id: snapshot.docs.first.id,
            patientId: data['patientId'] ?? '',
            patientName: data['patientName'] ?? 'Unknown Patient',
            type: data['type'] ?? 'General Consultation',
            dateTime: appointmentDateTime,
            location: data['location'] ?? 'N/A',
            status: parsedStatus,
            notes: data['notes'] ?? '',
            assignedToId: data['assignedToId'], // Include assignedToId
            assignedToName: data['assignedToName'], // Include assignedToName
            createdAt: (data['createdAt'] as Timestamp).toDate(), // Include createdAt
          );
          _isLoadingUpcomingAppointment = false;
        });
      } else {
        setState(() {
          _upcomingAppointment = null; // No upcoming appointment
          _isLoadingUpcomingAppointment = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming appointment: $e');
      if (currentContext.mounted) {
        setState(() {
          _upcomingAppointmentErrorMessage = 'Error loading upcoming appointment: $e';
          _isLoadingUpcomingAppointment = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoadingUserData = true; // Show loading while logging out
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (currentContext.mounted) {
        // After logout, navigate back to the RoleRouterScreen to handle redirection
        Navigator.pushAndRemoveUntil(
          currentContext,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
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
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Medical Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Prescriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
