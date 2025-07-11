import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/patient.dart'; // Import the Patient model (which contains Appointment)
import 'package:care_flow/screens/appointment_details_page.dart'; // Import the AppointmentDetailsPage
// For debugPrint

class NurseAppointmentsScreen extends StatefulWidget {
  const NurseAppointmentsScreen({super.key});

  @override
  State<NurseAppointmentsScreen> createState() => _NurseAppointmentsScreenState();
}

class _NurseAppointmentsScreenState extends State<NurseAppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in. Cannot fetch appointments.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch appointments where the 'assignedToId' matches the current nurse's UID
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('assignedToId', isEqualTo: _currentUser!.uid)
          .orderBy('dateTime', descending: true) // Order by most recent appointments first
          .get();

      List<Appointment> fetchedAppointments = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();

        return Appointment(
          id: doc.id,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? 'Unknown Patient',
          type: data['type'] ?? 'General Consultation', // <--- Added 'type' field here
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
          _appointments = fetchedAppointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e'); // Changed print to debugPrint
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading appointments: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.green.shade700, // Distinct color for nurse appointments
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      )
          : _appointments.isEmpty
          ? const Center(
        child: Text('You have no appointments scheduled yet.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appointment.patientName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appointment.statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          appointment.status.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${appointment.type}', // Display the appointment type
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(appointment.dateTime)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Time: ${TimeOfDay.fromDateTime(appointment.dateTime).format(context)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${appointment.location}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${appointment.notes.isNotEmpty ? appointment.notes : 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to AppointmentDetailsPage, passing the appointment object
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailsPage(appointment: appointment),
                          ),
                        );
                        debugPrint('View details for appointment: ${appointment.id}'); // Changed print to debugPrint
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade700),
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
        },
      ),
    );
  }
}
