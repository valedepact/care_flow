import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // NEW: Import table_calendar
import 'package:care_flow/models/appointment.dart'; // Correctly import the Appointment model
import 'package:care_flow/screens/appointment_details_page.dart'; // Import the AppointmentDetailsPage
import 'package:care_flow/screens/add_appointment_screen.dart'; // NEW: Import AddAppointmentScreen
import 'dart:collection'; // For LinkedHashMap

class NurseAppointmentsScreen extends StatefulWidget {
  const NurseAppointmentsScreen({super.key});

  @override
  State<NurseAppointmentsScreen> createState() => _NurseAppointmentsScreenState();
}

class _NurseAppointmentsScreenState extends State<NurseAppointmentsScreen> {
  User? _currentUser;
  String? _errorMessage;

  // Calendar related state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Use LinkedHashMap to maintain insertion order for events (important for UI consistency)
  final LinkedHashMap<DateTime, List<Appointment>> _events = LinkedHashMap<DateTime, List<Appointment>>(); // Changed to final
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
          _errorMessage = 'User not logged in. Cannot fetch appointments.';
        });
      }
    }
  }

  // Helper function to get events for a given day
  List<Appointment> _getEventsForDay(DateTime day) {
    // Normalize the day to ensure consistent keys (no time component)
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Callback for when a day is selected on the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // update `_focusedDay` to also call `onPageChanged`
        _selectedAppointments = _getEventsForDay(selectedDay);
      });
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
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('assignedToId', isEqualTo: _currentUser!.uid)
                .orderBy('dateTime', descending: false) // Order by date ascending for calendar
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('Error fetching appointments stream: ${snapshot.error}');
                return Center(child: Text('Error loading appointments: ${snapshot.error}'));
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
                      child: Text('You have no appointments scheduled yet.'),
                    ),
                  ],
                );
              }

              // Process fetched appointments for the calendar
              _events.clear(); // Clear previous events
              for (var doc in snapshot.data!.docs) {
                // The Appointment.fromFirestore factory already handles the overdue logic
                // and sets the correct status and statusColor.
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
          // Section title for selected day's appointments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _selectedDay != null
                  ? 'Appointments on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}:'
                  : 'Select a date to view appointments.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedAppointments.isEmpty
                ? Center(
              child: Text(
                _selectedDay != null
                    ? 'No appointments for this date.'
                    : 'Select a date to view appointments.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _selectedAppointments.length,
              itemBuilder: (context, index) {
                final appointment = _selectedAppointments[index];
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
                          'Type: ${appointment.type}',
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
                        // NEW: Display time remaining or overdue status
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            appointment.isOverdue
                                ? 'Status: Overdue'
                                : 'Time Remaining: ${appointment.getTimeRemainingString()}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: appointment.isOverdue ? Colors.red : Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final currentContext = context;
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to AddAppointmentScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAppointmentScreen(
                patientId: '', // Nurse can choose patient in AddAppointmentScreen
                patientName: '', // Nurse can choose patient in AddAppointmentScreen
              ),
            ),
          );
          debugPrint('Add New Appointment pressed');
        },
        label: const Text('Add Appointment'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Helper method to build the TableCalendar widget
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
          color: Colors.green.shade800,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green.shade800),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green.shade800),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.green.shade700,
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
