import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:care_flow/models/patient.dart'; // Reusing Appointment model for visits
import 'package:care_flow/screens/appointment_details_page.dart'; // IMPORTANT: Ensure this path is correct and the file exists!
// For debugPrint

class VisitSchedulePage extends StatefulWidget {
  const VisitSchedulePage({super.key});

  @override
  State<VisitSchedulePage> createState() => _VisitSchedulePageState();
}

class _VisitSchedulePageState extends State<VisitSchedulePage> {
  // Dummy data for scheduled visits.
  // In a real application, this would be fetched from a backend,
  // filtered by the current nurse and date.
  final List<Appointment> _scheduledVisits = [
    // Using Appointment model as visits are essentially appointments
    Appointment(
      id: 'visit_001',
      patientId: 'patient_id_001',
      patientName: 'John Kelly',
      type: 'Home Visit', // Added the missing 'type' field
      dateTime: DateTime.now().add(const Duration(hours: 1)), // Upcoming
      location: '123 Oak Ave, City',
      status: AppointmentStatus.upcoming,
      notes: 'Routine blood pressure check and medication reminder.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.upcoming),
    ),
    Appointment(
      id: 'visit_002',
      patientId: 'patient_id_002',
      patientName: 'Anna Davis',
      type: 'Follow-up', // Added the missing 'type' field
      dateTime: DateTime.now().add(const Duration(hours: 3)), // Upcoming
      location: '456 Pine St, Town',
      status: AppointmentStatus.upcoming,
      notes: 'Post-surgery wound dressing change.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.upcoming),
    ),
    Appointment(
      id: 'visit_003',
      patientId: 'patient_id_003',
      patientName: 'Greg Teri',
      type: 'Medication Delivery', // Added the missing 'type' field
      dateTime: DateTime.now().subtract(const Duration(hours: 2)), // Completed (past)
      location: '789 Elm Rd, Village',
      status: AppointmentStatus.completed,
      notes: 'Insulin injection and glucose monitoring. Patient stable.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.completed),
    ),
    Appointment(
      id: 'visit_004',
      patientId: 'patient_id_004',
      patientName: 'Walter Reed',
      type: 'Check-up', // Added the missing 'type' field
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 10)), // Missed (past)
      location: '101 Birch Ln, Hamlet',
      status: AppointmentStatus.missed,
      notes: 'Patient was not home. Attempted contact.',
      statusColor: Appointment.getColorForStatus(AppointmentStatus.missed),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Sort visits by date and time
    _scheduledVisits.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Schedule'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _scheduledVisits.isEmpty
          ? const Center(
        child: Text('No visits scheduled for today.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _scheduledVisits.length,
        itemBuilder: (context, index) {
          final visit = _scheduledVisits[index];
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
                        visit.patientName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: visit.statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          visit.status.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${visit.type}', // Display the appointment type
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(visit.dateTime)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Time: ${DateFormat('h:mm a').format(visit.dateTime)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${visit.location}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${visit.notes.isNotEmpty ? visit.notes : 'N/A'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Action buttons for nurse to manage visits
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to AppointmentDetailsPage (which can serve as Visit Details)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailsPage(appointment: visit),
                            ),
                          );
                          debugPrint('View details for visit: ${visit.id}'); // Changed print to debugPrint
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (visit.status == AppointmentStatus.upcoming)
                        ElevatedButton.icon(
                          onPressed: () {
                            // Simulate marking as completed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Marked visit for ${visit.patientName} as completed!')),
                            );
                            debugPrint('Marked visit ${visit.id} as completed'); // Changed print to debugPrint
                            // In a real app, update the status in the backend and refresh the list
                            setState(() {
                              final indexToUpdate = _scheduledVisits.indexWhere((element) => element.id == visit.id);
                              if (indexToUpdate != -1) {
                                _scheduledVisits[indexToUpdate] = Appointment(
                                  id: visit.id,
                                  patientId: visit.patientId,
                                  patientName: visit.patientName,
                                  type: visit.type, // Ensure 'type' is passed here too
                                  dateTime: visit.dateTime,
                                  location: visit.location,
                                  status: AppointmentStatus.completed,
                                  notes: visit.notes,
                                  statusColor: Appointment.getColorForStatus(AppointmentStatus.completed),
                                );
                              }
                            });
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (visit.status == AppointmentStatus.upcoming)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'add_notes') {
                              // Simulate adding notes
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Add Visit Notes functionality (dummy)')),
                              );
                              debugPrint('Add notes for visit ${visit.id}'); // Changed print to debugPrint
                              // Navigate to a screen to add/edit notes for this specific visit
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => AddVisitNotesScreen(visit: visit)));
                            } else if (value == 'record_vitals') {
                              // Simulate recording vitals
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Record Vitals functionality (dummy)')),
                              );
                              debugPrint('Record vitals for visit ${visit.id}'); // Changed print to debugPrint
                              // Navigate to a screen to record vitals for this specific visit
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => RecordVitalsScreen(visit: visit)));
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'add_notes',
                              child: Text('Add Visit Notes'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'record_vitals',
                              child: Text('Record Vitals'),
                            ),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                    ],
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
