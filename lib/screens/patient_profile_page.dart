import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/screens/edit_patient_screen.dart'; // Import EditPatientScreen
import 'package:care_flow/screens/medical_records_page.dart'; // Import MedicalRecordsPage (assuming this is your patient_medical_records_screen.dart)
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Corrected: Import PatientPrescriptionsScreen
import 'package:care_flow/screens/patient_notes_screen.dart'; // Import PatientNotesScreen

class PatientProfilePage extends StatefulWidget {
  final String patientId; // Required patientId
  final String patientName; // For display purposes (initial load)

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

  // Fetches patient details from Firestore using the provided patientId
  Future<void> _fetchPatientDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (!mounted) return; // Check mounted after await

      if (doc.exists) {
        setState(() {
          _patient = Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Patient with ID ${widget.patientId} not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patient details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading patient details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient?.name ?? widget.patientName), // Use fetched name or initial name
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_patient != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final currentContext = context; // Capture context
                // Navigate to EditPatientScreen
                await Navigator.push(
                  currentContext, // Use captured context
                  MaterialPageRoute(
                    builder: (context) => EditPatientScreen(patient: _patient!),
                  ),
                );
                // Refresh patient details after returning from edit screen
                if (currentContext.mounted) { // Check mounted before calling _fetchPatientDetails
                  _fetchPatientDetails();
                }
              },
              tooltip: 'Edit Patient',
            ),
        ],
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
          : _patient == null
          ? const Center(child: Text('Patient data is unavailable.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _patient!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    'ID: ${_patient!.id}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Information
            _buildSectionTitle(context, 'Contact Information'),
            _buildInfoCard(
              context,
              children: [
                _buildInfoRow(Icons.phone, 'Contact', _patient!.contact),
                if (_patient!.email != null && _patient!.email!.isNotEmpty)
                  _buildInfoRow(Icons.email, 'Email', _patient!.email!),
                _buildInfoRow(Icons.location_on, 'Address', _patient!.address),
              ],
            ),
            const SizedBox(height: 24),

            // Medical Information
            _buildSectionTitle(context, 'Medical Information'),
            _buildInfoCard(
              context,
              children: [
                _buildInfoRow(Icons.medical_services, 'Condition', _patient!.condition),
                _buildInfoRow(Icons.calendar_today, 'Age', _patient!.age),
                _buildInfoRow(Icons.wc, 'Gender', _patient!.gender),
                _buildInfoRow(Icons.medication, 'Medications', _patient!.medications.join(', ')),
                _buildInfoRow(Icons.history, 'Treatment History', _patient!.treatmentHistory.join(', ')),
                _buildInfoRow(Icons.event_note, 'Last Visit', _patient!.lastVisit),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Contact
            _buildSectionTitle(context, 'Emergency Contact'),
            _buildInfoCard(
              context,
              children: [
                _buildInfoRow(Icons.person_add, 'Name', _patient!.emergencyContactName ?? 'N/A'),
                _buildInfoRow(Icons.phone_in_talk, 'Number', _patient!.emergencyContactNumber ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions for Patient Management
            _buildSectionTitle(context, 'Patient Management'),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.folder_open,
                  label: 'Medical Records',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalRecordsPage( // Using MedicalRecordsPage
                          patientId: _patient!.id,
                          patientName: _patient!.name,
                        ),
                      ),
                    );
                    debugPrint('View Medical Records for ${_patient!.name}');
                  },
                  color: Colors.indigo,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.medication,
                  label: 'Prescriptions',
                  onPressed: () {
                    // Corrected: Navigate to PatientPrescriptionsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientPrescriptionsScreen( // Use PatientPrescriptionsScreen
                          patientId: _patient!.id,
                          patientName: _patient!.name,
                        ),
                      ),
                    );
                    debugPrint('View Prescriptions for ${_patient!.name}');
                  },
                  color: Colors.green,
                ),
                _buildActionButton(
                  context,
                  icon: Icons.notes,
                  label: 'Patient Notes',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientNotesScreen(
                          patientId: _patient!.id,
                          patientName: _patient!.name,
                        ),
                      ),
                    );
                    debugPrint('View Patient Notes for ${_patient!.name}');
                  },
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
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
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
