import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/patient.dart'; // Import Patient model for AppointmentStatus

class NurseAppointmentsScreen extends StatefulWidget {
  const NurseAppointmentsScreen({super.key});

  @override
  State<NurseAppointmentsScreen> createState() => _NurseAppointmentsScreenState();
}

class _NurseAppointmentsScreenState extends State<NurseAppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
    try {
      // Fetch all appointments.
      // In a more advanced scenario, you might filter by:
      // .where('assignedToId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      // .where('dateTime', isGreaterThanOrEqualTo: DateTime.now())
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .orderBy('dateTime', descending: false) // Order by date ascending
          .get();

      List<Appointment> fetchedAppointments = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();

        return Appointment(
          id: doc.id,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? 'Unknown Patient',
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
      print('Error fetching appointments: $e');
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        child: Text('No appointments found. Schedule a new one!'),
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
                  Text(
                    'Patient: ${appointment.patientName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${appointment.type}', // Assuming 'type' field in Appointment
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(appointment.dateTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Time: ${DateFormat('h:mm a').format(appointment.dateTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Location: ${appointment.location}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Chip(
                        label: Text(appointment.status.name.toUpperCase()),
                        backgroundColor: appointment.statusColor,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (appointment.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${appointment.notes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle viewing/editing appointment details
                        print('View/Edit Appointment ID: ${appointment.id}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing details for appointment ID: ${appointment.id}')),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
