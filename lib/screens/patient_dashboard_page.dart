import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
// For debugPrint

import 'package:care_flow/screens/emergency_alerts_page.dart';
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage (for scheduling)
// Import the new MyAlertsScreen (for viewing)
import 'package:care_flow/screens/role_router_screen.dart'; // Import RoleRouterScreen for logout navigation
import 'package:care_flow/models/patient.dart'; // Import the Patient model (contains Appointment model)
import 'package:care_flow/screens/my_appointments_page.dart'; // Import MyAppointmentsPage
import 'package:care_flow/screens/patient_medical_records_screen.dart'; // Import PatientMedicalRecordsScreen
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Import PatientPrescriptionsScreen
import 'package:care_flow/screens/patient_notes_screen.dart'; // Import PatientNotesScreen
import 'package:care_flow/screens/messaging_page.dart'; // Import the MessagingPage (ChatListPage)
import 'package:care_flow/screens/appointment_details_page.dart'; // Import AppointmentDetailsPage

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

  @override
  void initState() {
    super.initState();
    _fetchPatientDataAndUpcomingAppointment();
  }

  Future<void> _fetchPatientDataAndUpcomingAppointment() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
      if (mounted) {
        // This navigation should ideally be handled by RoleRouterScreen
        // if this page is only reachable after login.
        // For now, keeping it here for immediate feedback.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
        );
      }
    }
  }

  Future<void> _fetchUpcomingAppointment(String patientId) async {
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

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = snapshot.docs.first.data() as Map<String, dynamic>;

        // Ensure 'type' is present in the Firestore data or provide a default
        String appointmentType = data['type'] ?? 'General Consultation';

        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();

        setState(() {
          _upcomingAppointment = Appointment(
            id: snapshot.docs.first.id,
            patientId: data['patientId'] ?? '',
            patientName: data['patientName'] ?? 'Unknown Patient',
            type: appointmentType, // Use the retrieved or default type
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
      if (mounted) {
        setState(() {
          _upcomingAppointmentErrorMessage = 'Error loading upcoming appointment: $e';
          _isLoadingUpcomingAppointment = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoadingUserData = true; // Show loading while logging out
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // After logout, navigate back to the RoleRouterScreen to handle redirection
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      body: (_isLoadingUserData || _isLoadingUpcomingAppointment)
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Center(
        child: SingleChildScrollView(
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
                'Welcome, $_patientName!', // Dynamic patient name
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
                spacing: 16.0,
                runSpacing: 16.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildDashboardButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'My Appointments',
                    onPressed: () {
                      // Navigate to the MyAppointmentsPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyAppointmentsPage()),
                      );
                      debugPrint('My Appointments pressed - Navigating to appointments list');
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.folder_open,
                    label: 'Medical Records',
                    onPressed: () {
                      // Ensure patientId is available before navigating
                      if (_patientId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientMedicalRecordsScreen(
                              patientId: _patientId,
                              patientName: _patientName,
                            ),
                          ),
                        );
                        debugPrint('Medical Records pressed - Navigating to medical records');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient ID not available. Cannot view records.')),
                        );
                      }
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.message,
                    label: 'Messages',
                    onPressed: () {
                      // Navigate to the ChatListPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatListPage()),
                      );
                      debugPrint('Messages pressed - Navigating to chat list');
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.medication,
                    label: 'Prescriptions',
                    onPressed: () {
                      // Ensure patientId is available before navigating
                      if (_patientId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientPrescriptionsScreen(
                              patientId: _patientId,
                              patientName: _patientName,
                            ),
                          ),
                        );
                        debugPrint('Prescriptions pressed - Navigating to prescriptions list');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient ID not available. Cannot view prescriptions.')),
                        );
                      }
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.notes, // Icon for notes
                    label: 'Notes',
                    onPressed: () {
                      // Ensure patientId is available before navigating
                      if (_patientId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientNotesScreen(
                              patientId: _patientId,
                              patientName: _patientName,
                            ),
                          ),
                        );
                        debugPrint('Notes pressed - Navigating to patient notes');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient ID not available. Cannot view notes.')),
                        );
                      }
                    },
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.notifications_active,
                    label: 'Emergency Alert',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyAlertsPage()),
                      );
                      debugPrint('Emergency Alert pressed');
                    },
                    color: Colors.red.shade700,
                  ),
                  _buildDashboardButton(
                    context,
                    icon: Icons.add_alarm,
                    label: 'Set Reminder',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AlertsPage()),
                      );
                      debugPrint('Set Reminder pressed from Patient Dashboard');
                    },
                    color: Colors.teal,
                  ),
                  // New: My Alerts button for patients
                  _buildDashboardButton(
                    context,
                    icon: Icons.list_alt, // Icon for a list/alerts
                    label: 'My Alerts',
                    onPressed: () {
                      // Implement navigation to MyAlertsScreen if you create one for patients
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('My Alerts functionality coming soon!')),
                      );
                      debugPrint('My Alerts pressed from Patient Dashboard');
                    },
                    color: Colors.deepPurple, // A distinct color
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Upcoming Appointment Card (now dynamic)
              _isLoadingUpcomingAppointment
                  ? const Center(child: CircularProgressIndicator())
                  : _upcomingAppointmentErrorMessage.isNotEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _upcomingAppointmentErrorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              )
                  : _upcomingAppointment == null
                  ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Upcoming Appointments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'You currently have no appointments scheduled. Check back later or contact your care team to schedule one.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              )
                  : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Appointment: ${_upcomingAppointment!.type}', // Display type
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            _upcomingAppointment!.patientName, // Display patient name from appointment
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.grey, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM d, yyyy - h:mm a').format(_upcomingAppointment!.dateTime),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to AppointmentDetailsPage with the actual appointment object
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsPage(appointment: _upcomingAppointment!),
                              ),
                            );
                            debugPrint('View Appointment Details for ID: ${_upcomingAppointment!.id}');
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
          backgroundColor: color ?? Theme.of(context).colorScheme.surfaceContainerHighest, // Use provided color or default
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
