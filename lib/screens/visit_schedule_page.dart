import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user ID
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:care_flow/models/appointment.dart'; // Corrected: Import the Appointment model
import 'package:care_flow/screens/appointment_details_page.dart'; // IMPORTANT: Ensure this path is correct and the file exists!

class VisitSchedulePage extends StatefulWidget {
  const VisitSchedulePage({super.key});

  @override
  State<VisitSchedulePage> createState() => _VisitSchedulePageState();
}

class _VisitSchedulePageState extends State<VisitSchedulePage> {
  User? _currentUser;
  String? _errorMessage;

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
          _errorMessage = 'User not logged in. Cannot fetch schedule.';
        });
      }
    }
  }

  Future<void> _markAppointmentAsCompleted(Appointment appointment) async {
    final currentContext = context; // Capture context
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointment.id).update({
        'status': AppointmentStatus.completed.toString().split('.').last,
      });
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Visit for ${appointment.patientName} marked as completed!')),
        );
      }
      debugPrint('Marked visit ${appointment.id} as completed in Firestore.');
    } catch (e) {
      debugPrint('Error marking appointment as completed: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to mark as completed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Visit Schedule'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage ?? 'Please log in to view your schedule.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // Define start and end of today for querying
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Schedule'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('assignedToId', isEqualTo: _currentUser!.uid) // Filter by current nurse
            .where('dateTime', isGreaterThanOrEqualTo: startOfToday)
            .where('dateTime', isLessThanOrEqualTo: endOfToday)
            .orderBy('dateTime', descending: false) // Order by date ascending
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching visits stream: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading visits: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No visits scheduled for today.'),
            );
          }

          final scheduledVisits = snapshot.data!.docs.map((doc) {
            return Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: scheduledVisits.length,
            itemBuilder: (context, index) {
              final visit = scheduledVisits[index];
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
                              debugPrint('View details for visit: ${visit.id}');
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
                              onPressed: () => _markAppointmentAsCompleted(visit), // Call the async function
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
                                  debugPrint('Add notes for visit ${visit.id}');
                                  // Navigate to a screen to add/edit notes for this specific visit
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => AddVisitNotesScreen(visit: visit)));
                                } else if (value == 'record_vitals') {
                                  // Simulate recording vitals
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Record Vitals functionality (dummy)')),
                                  );
                                  debugPrint('Record vitals for visit ${visit.id}');
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
          );
        },
      ),
    );
  }
}
