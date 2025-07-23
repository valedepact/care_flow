import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user ID
import 'package:intl/intl.dart'; // For date and time formatting
import 'package:care_flow/models/appointment.dart'; // Corrected: Import the Appointment model
import 'package:care_flow/screens/appointment_details_page.dart'; // IMPORTANT: Ensure this path is correct and the file exists!
import 'package:table_calendar/table_calendar.dart'; // NEW: Import table_calendar
import 'dart:collection'; // NEW: For LinkedHashMap

class VisitSchedulePage extends StatefulWidget {
  const VisitSchedulePage({super.key});

  @override
  State<VisitSchedulePage> createState() => _VisitSchedulePageState();
}

class _VisitSchedulePageState extends State<VisitSchedulePage> {
  User? _currentUser;
  String? _errorMessage;

  // NEW: Calendar related state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Use LinkedHashMap to maintain insertion order for events (important for UI consistency)
  final LinkedHashMap<DateTime, List<Appointment>> _events = LinkedHashMap<DateTime, List<Appointment>>();
  List<Appointment> _selectedAppointments = []; // Appointments for the currently selected day

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _selectedDay = _focusedDay; // Initially select today
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

  // NEW: Helper function to get events for a given day
  List<Appointment> _getEventsForDay(DateTime day) {
    // Normalize the day to ensure consistent keys (no time component)
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // NEW: Callback for when a day is selected on the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // update `_focusedDay` to also call `onPageChanged`
        _selectedAppointments = _getEventsForDay(selectedDay);
      });
    }
  }

  Future<void> _markAppointmentAsCompleted(Appointment appointment) async {
    final currentContext = context; // Capture context
    debugPrint('Attempting to mark appointment ID: ${appointment.id} as completed.');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Schedule'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column( // NEW: Use Column to arrange calendar and list
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('assignedToId', isEqualTo: _currentUser!.uid) // Filter by current nurse
            // NEW: Fetch a wider range of dates for the calendar
                .where('dateTime', isGreaterThanOrEqualTo: kFirstDay)
                .where('dateTime', isLessThanOrEqualTo: kLastDay)
                .orderBy('dateTime', descending: false) // Order by date ascending for calendar
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
                // If no data, clear events and selected appointments
                _events.clear();
                _selectedAppointments.clear();
                return Column(
                  children: [
                    _buildCalendar(), // Still show calendar even if no appointments
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('You have no visits scheduled yet within the calendar range.'),
                    ),
                  ],
                );
              }

              // Process fetched appointments for the calendar
              _events.clear(); // Clear previous events
              for (var doc in snapshot.data!.docs) {
                final appointment = Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                // Normalize date to UTC midnight for consistent grouping
                final normalizedDate = DateTime.utc(appointment.dateTime.year, appointment.dateTime.month, appointment.dateTime.day);
                if (_events[normalizedDate] == null) {
                  _events[normalizedDate] = [];
                }
                _events[normalizedDate]!.add(appointment);
              }

              // Update selected appointments based on the current _selectedDay
              // This ensures the list below the calendar updates when data changes
              _selectedAppointments = _getEventsForDay(_selectedDay ?? _focusedDay);

              return _buildCalendar();
            },
          ),
          const SizedBox(height: 8.0),
          // NEW: Section title for selected day's appointments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _selectedDay != null
                  ? 'Visits on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}:'
                  : 'Select a date to view visits.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded( // NEW: Wrap ListView.builder in Expanded
            child: _selectedAppointments.isEmpty
                ? Center(
              child: Text(
                _selectedDay != null
                    ? 'No visits for this date.'
                    : 'Select a date to view visits.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _selectedAppointments.length,
              itemBuilder: (context, index) {
                final visit = _selectedAppointments[index]; // Use _selectedAppointments
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
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Helper method to build the TableCalendar widget
  Widget _buildCalendar() {
    return TableCalendar<Appointment>(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay, // Load events for each day
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false, // Hide format button
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(25),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.red.shade400, // Dot color for days with events
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3, // Max dots to show for events
      ),
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      // Ensure the range of days for the calendar is reasonable
      rangeStartDay: null,
      rangeEndDay: null,
    );
  }
}

// Constants for calendar range (can be adjusted)
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
