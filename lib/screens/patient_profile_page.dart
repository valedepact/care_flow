import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/screens/patient_notes_screen.dart'; // Import PatientNotesScreen
import 'package:care_flow/screens/medical_records_page.dart'; // Import MedicalRecordsPage
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Import PatientPrescriptionsScreen
import 'package:care_flow/screens/edit_patient_screen.dart'; // NEW: Import EditPatientScreen
import 'package:care_flow/screens/add_appointment_screen.dart'; // NEW: Import AddAppointmentScreen
// For debugPrint

class PatientProfilePage extends StatefulWidget {
  final String patientId;
  final String patientName; // Added for convenience in AppBar title

  const PatientProfilePage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  Patient? _patient;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  Future<void> _fetchPatientDetails() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (!currentContext.mounted) return;

      if (doc.exists) {
        setState(() {
          _patient = Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Patient not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patient details: $e');
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'Failed to load patient details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Profile'),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _patient!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Fix: Safely access email and provide fallback
                  Text(
                    _patient!.email.isNotEmpty ? _patient!.email : 'No Email',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Patient Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.perm_identity, 'Patient ID', _patient!.id),
                    // FIX: Ensure age is always a string when passed to _buildInfoRow
                    _buildInfoRow(context, Icons.cake, 'Age', _patient!.age.toString()),
                    _buildInfoRow(context, Icons.wc, 'Gender', _patient!.gender),
                    _buildInfoRow(context, Icons.phone, 'Contact', _patient!.contact),
                    _buildInfoRow(context, Icons.home, 'Address', _patient!.address),
                    _buildInfoRow(context, Icons.medical_information, 'Condition', _patient!.condition),
                    _buildInfoRow(context, Icons.assignment_ind, 'Status', _patient!.status.toUpperCase()),
                    if (_patient!.nurseId != null)
                      _buildInfoRow(context, Icons.local_hospital, 'Assigned Nurse ID', _patient!.nurseId!),
                    if (_patient!.emergencyContactName != null && _patient!.emergencyContactName!.isNotEmpty)
                      _buildInfoRow(context, Icons.emergency, 'Emergency Contact', '${_patient!.emergencyContactName!} (${_patient!.emergencyContactNumber ?? 'N/A'})'),

                    const SizedBox(height: 20),
                    Text(
                      'Location Information', // New Section
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const Divider(height: 24),
                    // Fix: Safely access locationName, latitude, longitude
                    if (_patient!.locationName != null && _patient!.locationName!.isNotEmpty)
                      _buildInfoRow(context, Icons.place, 'Location Name', _patient!.locationName!),
                    if (_patient!.latitude != null && _patient!.longitude != null)
                      _buildInfoRow(context, Icons.gps_fixed, 'Coordinates', '${_patient!.latitude!.toStringAsFixed(6)}, ${_patient!.longitude!.toStringAsFixed(6)}')
                    else
                      _buildInfoRow(context, Icons.location_off, 'Location', 'Not provided'),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions (Buttons)
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                _buildActionButton(
                  context,
                  label: 'Medical Records',
                  icon: Icons.receipt_long,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalRecordsPage(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                    debugPrint('Medical Records pressed');
                  },
                  color: Colors.indigo,
                ),
                _buildActionButton(
                  context,
                  label: 'Prescriptions',
                  icon: Icons.medical_services,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientPrescriptionsScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                    debugPrint('Prescriptions pressed');
                  },
                  color: Colors.purple,
                ),
                _buildActionButton(
                  context,
                  label: 'Notes',
                  icon: Icons.notes,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientNotesScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                    debugPrint('Notes pressed');
                  },
                  color: Colors.orange,
                ),
                _buildActionButton(
                  context,
                  label: 'Add Appointment',
                  icon: Icons.calendar_month,
                  onPressed: () {
                    // NEW: Navigate to AddAppointmentScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAppointmentScreen(
                          patientId: widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ),
                    );
                    debugPrint('Add Appointment pressed - Navigating to AddAppointmentScreen');
                  },
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Edit Patient Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // NEW: Implement Edit Patient functionality
                  if (_patient != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPatientScreen(patient: _patient!),
                      ),
                    );
                    debugPrint('Edit Patient pressed - Navigating to EditPatientScreen');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient data not loaded. Cannot edit.')),
                    );
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Patient Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton(BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
