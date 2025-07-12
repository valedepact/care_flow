import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/appointment.dart'; // Correctly import the Appointment model
import 'package:care_flow/screens/appointment_details_page.dart'; // Import the AppointmentDetailsPage
// Removed: import 'package:flutter/foundation.dart'; // debugPrint is available via material.dart

class NurseAppointmentsScreen extends StatefulWidget {
  const NurseAppointmentsScreen({super.key});

  @override
  State<NurseAppointmentsScreen> createState() => _NurseAppointmentsScreenState();
}

class _NurseAppointmentsScreenState extends State<NurseAppointmentsScreen> {
  User? _currentUser;
  String? _errorMessage; // No longer needed for StreamBuilder, but useful for initial user check

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in. Cannot fetch appointments.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage ?? 'Please log in to view your appointments.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.green.shade700, // Distinct color for nurse appointments
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('assignedToId', isEqualTo: _currentUser!.uid)
            .orderBy('dateTime', descending: true) // Order by most recent appointments first
            .snapshots(), // Use snapshots for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching appointments stream: ${snapshot.error}');
            return Center(child: Text('Error loading appointments: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('You have no appointments scheduled yet.'),
            );
          }

          final appointments = snapshot.data!.docs.map((doc) {
            return Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
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
                            final currentContext = context; // Capture context
                            // Navigate to AppointmentDetailsPage, passing the appointment object
                            Navigator.push(
                              currentContext,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsPage(appointment: appointment),
                              ),
                            );
                            debugPrint('View details for appointment: ${appointment.id}');
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
          );
        },
      ),
    );
  }
}
