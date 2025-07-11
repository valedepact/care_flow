import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:care_flow/screens/emergency_alerts_page.dart';
import 'package:care_flow/screens/alert_page.dart'; // Import the revamped AlertsPage (for scheduling)
import 'package:care_flow/screens/my_alerts_screen.dart'; // Import the new MyAlertsScreen (for viewing)
import 'package:care_flow/screens/role_router_screen.dart'; // Import RoleRouterScreen for logout navigation
import 'package:care_flow/models/patient.dart'; // Import the Patient model (contains Appointment model)
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/screens/my_appointments_page.dart'; // Import MyAppointmentsPage
import 'package:care_flow/screens/patient_medical_records_screen.dart'; // Import PatientMedicalRecordsScreen
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Import PatientPrescriptionsScreen
import 'package:care_flow/screens/patient_notes_screen.dart'; // Import PatientNotesScreen
import 'package:care_flow/screens/messaging_page.dart'; // Import the MessagingPage (ChatListPage)

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  String _patientName = 'Loading...';
  String _patientId = '';
  bool _isLoading = true;
  Appointment? _upcomingAppointment; // To store the fetched upcoming appointment

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
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
            _patientId = currentUser.uid;
          });
          await _fetchUpcomingAppointment(currentUser.uid); // Fetch upcoming appointment
        } else {
          print('Patient document not found for UID: ${currentUser.uid}');
          setState(() {
            _patientName = 'Patient (Profile Incomplete)';
            _patientId = currentUser.uid;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching patient data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading patient data: $e')),
          );
          setState(() {
            _patientName = 'Error Loading';
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _fetchUpcomingAppointment(String patientId) async {
    try {
      QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('dateTime', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('dateTime')
          .limit(1)
          .get();

      if (appointmentSnapshot.docs.isNotEmpty) {
        DocumentSnapshot appointmentDoc = appointmentSnapshot.docs.first;
        Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;

        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();

        setState(() {
          _upcomingAppointment = Appointment(
            id: appointmentDoc.id,
            patientId: data['patientId'],
            patientName: data['patientName'],
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
          _isLoading = false;
        });
      } else {
        setState(() {
          _upcomingAppointment = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching upcoming appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading upcoming appointment: $e')),
        );
        setState(() {
          _upcomingAppointment = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleRouterScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
        setState(() {
          _isLoading = false;
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
      body: _isLoading
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
                'Welcome, $_patientName!',
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
                      print('My Appointments pressed - Navigating to appointments list');
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
                        print('Medical Records pressed - Navigating to medical records');
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
                      print('Messages pressed - Navigating to chat list');
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
                        print('Prescriptions pressed - Navigating to prescriptions list');
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
                        print('Notes pressed - Navigating to patient notes');
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
                      print('Emergency Alert pressed');
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
                      print('Set Reminder pressed from Patient Dashboard');
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
                      print('My Alerts pressed from Patient Dashboard');
                    },
                    color: Colors.deepPurple, // A distinct color
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Upcoming Appointment Card (Dynamic)
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
                      if (_upcomingAppointment != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.event, color: Colors.grey, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_upcomingAppointment!.patientName} - ${_upcomingAppointment!.location}',
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey, size: 24),
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
                              // Navigate to AppointmentDetailsPage, passing the appointment object
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppointmentDetailsPage(appointment: _upcomingAppointment!),
                                ),
                              );
                              print('View Appointment Details pressed for ID: ${_upcomingAppointment!.id}');
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
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No upcoming appointments found.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      ],
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
    Color? color,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.surfaceVariant,
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
}
