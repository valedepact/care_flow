import 'package:flutter/material.dart';
import 'package:care_flow/models/appointment.dart'; // Import the Appointment model
import 'package:care_flow/screens/appointment_details_page.dart'; // Import the new AppointmentDetailsPage

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  // Dummy list of appointments for demonstration
  final List<Appointment> _appointments = [
    Appointment(
      id: 'app_001',
      patientId: 'patient_id_789', // Assuming this is the current patient
      patientName: 'Patient John',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 10, minutes: 30)),
      location: 'Clinic A, Room 101',
      status: AppointmentStatus.upcoming,
      notes: 'Routine check-up.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.upcoming),
    ),
    Appointment(
      id: 'app_002',
      patientId: 'patient_id_789',
      patientName: 'Patient John',
      dateTime: DateTime.now().subtract(const Duration(days: 5, hours: 14)),
      location: 'Online Teleconsultation',
      status: AppointmentStatus.completed,
      notes: 'Follow-up on medication.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.completed),
    ),
    Appointment(
      id: 'app_003',
      patientId: 'patient_id_789',
      patientName: 'Patient John',
      dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 9)),
      location: 'Clinic B, Lab',
      status: AppointmentStatus.missed,
      notes: 'Blood test appointment. Patient did not show up.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.missed),
    ),
    Appointment(
      id: 'app_004',
      patientId: 'patient_id_789',
      patientName: 'Patient John',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 16)),
      location: 'Clinic A, Room 203',
      status: AppointmentStatus.upcoming,
      notes: 'Vaccination appointment.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.upcoming),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _appointments.isEmpty
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
                        '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                        print('View details for appointment: ${appointment.id}');
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
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
