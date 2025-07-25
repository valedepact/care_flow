import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:hive/hive.dart';
import 'package:care_flow/models/appointment.dart';
import 'package:care_flow/models/patient.dart';
// Import Patient model (for total patients)
// Import Appointment model (for visit summary)
// For date formatting
// For debugPrint

class NurseReportsScreen extends StatefulWidget {
  const NurseReportsScreen({super.key});

  @override
  State<NurseReportsScreen> createState() => _NurseReportsScreenState();
}

class _NurseReportsScreenState extends State<NurseReportsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  // Data for Patient Visit Summary
  int _totalVisitsLast30Days = 0;
  int _completedVisitsLast30Days = 0;
  int _missedVisitsLast30Days = 0;
  int _upcomingVisitsLast30Days = 0;
  int _cancelledVisitsLast30Days = 0;

  // Data for Overall Patient Status Summary
  int _totalPatients = 0;
  // Dummy counts for specific statuses, as Patient model doesn't have a 'status' field
  int _stablePatients = 0;
  int _improvingPatients = 0;
  int _criticalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Load from Hive first
    var appointmentBox = Hive.box<Appointment>('appointments');
    var patientBox = Hive.box<Patient>('patients');
    final DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final appointments = appointmentBox.values.where((a) => a.dateTime.isAfter(thirtyDaysAgo)).toList();
    final patients = patientBox.values.toList();

    _totalVisitsLast30Days = appointments.length;
    _completedVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.completed).length;
    _missedVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.missed).length;
    _upcomingVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.upcoming).length;
    _cancelledVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;

    _totalPatients = patients.length;
    _stablePatients = (_totalPatients * 0.8).round();
    _improvingPatients = (_totalPatients * 0.1).round();
    _criticalPatients = _totalPatients - _stablePatients - _improvingPatients;
    if (_criticalPatients < 0) _criticalPatients = 0;

    setState(() {
      _isLoading = false;
    });

    // 2. Fetch from Firestore, update Hive, and refresh UI
    try {
      QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
      List<Appointment> firestoreAppointments = appointmentSnapshot.docs.map((doc) =>
        Appointment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      await appointmentBox.clear();
      await appointmentBox.addAll(firestoreAppointments);

      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance.collection('patients').get();
      List<Patient> firestorePatients = patientSnapshot.docs.map((doc) =>
        Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      await patientBox.clear();
      await patientBox.addAll(firestorePatients);

      // Recalculate with latest data
      final appointments = appointmentBox.values.where((a) => a.dateTime.isAfter(thirtyDaysAgo)).toList();
      final patients = patientBox.values.toList();

      _totalVisitsLast30Days = appointments.length;
      _completedVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.completed).length;
      _missedVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.missed).length;
      _upcomingVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.upcoming).length;
      _cancelledVisitsLast30Days = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;

      _totalPatients = patients.length;
      _stablePatients = (_totalPatients * 0.8).round();
      _improvingPatients = (_totalPatients * 0.1).round();
      _criticalPatients = _totalPatients - _stablePatients - _improvingPatients;
      if (_criticalPatients < 0) _criticalPatients = 0;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load report data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.teal.shade700, // Changed color for reports screen
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview of Patient Care',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Patient Visit Summary (Last 30 Days)
            _buildReportCard(
              context,
              title: 'Patient Visit Summary (Last 30 Days)',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Total Visits', '$_totalVisitsLast30Days'),
                  _reportRow('Completed Visits', '$_completedVisitsLast30Days (${(_completedVisitsLast30Days / _totalVisitsLast30Days * 100).toStringAsFixed(1)}%)'),
                  _reportRow('Upcoming Visits', '$_upcomingVisitsLast30Days'),
                  _reportRow('Missed Visits', '$_missedVisitsLast30Days'),
                  _reportRow('Cancelled Visits', '$_cancelledVisitsLast30Days'),
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Monitor missed and cancelled visits for improvement.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Visit Completion Rate Chart',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medication Adherence Overview (Placeholder - requires dedicated data)
            _buildReportCard(
              context,
              title: 'Medication Adherence Overview',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Patients on Medication', '15'), // Dummy
                  _reportRow('High Adherence (>80%)', '12'), // Dummy
                  _reportRow('Moderate Adherence (50-80%)', '2'), // Dummy
                  _reportRow('Low Adherence (<50%)', '1'), // Dummy
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Generally good adherence, one patient requires closer monitoring. (Requires medication log data)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Adherence Rate Chart',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vital Signs Trends (Placeholder - requires dedicated data)
            _buildReportCard(
              context,
              title: 'Vital Signs Trends (Selected Patients)',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Patient John Kelly', 'BP: Stable, HR: Slight increase'), // Dummy
                  _reportRow('Patient Anna Davis', 'Temp: Normal, O2 Sat: 98%'), // Dummy
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Most vitals within normal range. Monitor John Kelly\'s heart rate. (Requires vital signs log data)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Vital Signs Trend Graph',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overall Patient Status Summary
            _buildReportCard(
              context,
              title: 'Overall Patient Status Summary',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Total Patients', '$_totalPatients'),
                  _reportRow('Stable Patients', '$_stablePatients'),
                  _reportRow('Improving Patients', '$_improvingPatients'),
                  _reportRow('Critical Patients', '$_criticalPatients'),
                  const SizedBox(height: 10),
                  Text(
                    'Action: Focus on critical patients and those requiring closer monitoring.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, {required String title, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800, // Adjusted color for card titles
              ),
            ),
            const Divider(height: 20, thickness: 1),
            content,
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
