import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:care_flow/screens/edit_patient_screen.dart'; // Import the EditPatientScreen
import 'package:care_flow/screens/patient_medical_records_screen.dart'; // Import PatientMedicalRecordsScreen
import 'package:care_flow/screens/patient_prescriptions_screen.dart';
import 'package:care_flow/screens/patient_notes_screen.dart';
import 'package:care_flow/models/patient.dart'; // Import the Patient model

class PatientProfilePage extends StatefulWidget {
  final String patientId; // Now expects a patient ID
  final String patientName; // Keep patientName for initial display while loading

  const PatientProfilePage({super.key, required this.patientId, required this.patientName});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  Patient? _currentPatient; // Nullable Patient object
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentPatient = Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Patient data not found for ID: ${widget.patientId}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patient data: $e');
      setState(() {
        _errorMessage = 'Error loading patient data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentPatient?.name ?? widget.patientName}\'s Profile'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
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
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              children: [
                _buildProfileHeader(context, _currentPatient!),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context: context,
                  title: '1. Personal & Demographic Information',
                  items: [
                    _infoRow(context, 'Full Name', _currentPatient!.name),
                    _infoRow(context, 'Age', _currentPatient!.age),
                    _infoRow(context, 'Gender', _currentPatient!.gender),
                    _infoRow(context, 'Contact', _currentPatient!.contact),
                    _infoRow(context, 'Insurance', 'Jubilee Health Plan'), // Hardcoded
                    _infoRow(context, 'Address', _currentPatient!.address),
                    _infoRow(context, 'Emergency Contact', '${_currentPatient!.emergencyContactName ?? 'N/A'} - ${_currentPatient!.emergencyContactNumber ?? 'N/A'}'),
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '2. Medical History',
                  items: [
                    _infoRow(context, 'Condition', _currentPatient!.condition),
                    _infoRow(context, 'Treatment History', _currentPatient!.treatmentHistory.join(', ')),
                    _infoRow(context, 'Past Illnesses', 'Asthma, Hypertension'), // Hardcoded
                    _infoRow(context, 'Surgeries', 'Appendectomy - 2018'), // Hardcoded
                    _infoRow(context, 'Immunizations', 'COVID-19, Tetanus'), // Hardcoded
                    _infoRow(context, 'Family History', 'Diabetes (Mother)'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '3. Medications',
                  items: [
                    _infoRow(context, 'Current Medications', _currentPatient!.medications.join(', ')),
                    _infoRow(context, 'OTC Drugs', 'Paracetamol'), // Hardcoded
                    _infoRow(context, 'Supplements', 'Vitamin D'), // Hardcoded
                    _infoRow(context, 'Allergies', 'Penicillin'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '4. Vital Signs',
                  items: [
                    _infoRow(context, 'Blood Pressure', '120/80 mmHg'), // Hardcoded
                    _infoRow(context, 'Heart Rate', '75 bpm'), // Hardcoded
                    _infoRow(context, 'Temperature', '36.8°C'), // Hardcoded
                    _infoRow(context, 'Respiratory Rate', '16 breaths/min'), // Hardcoded
                    _infoRow(context, 'Oxygen Saturation', '98%'), // Hardcoded
                    _infoRow(context, 'Weight & Height', '65 kg / 170 cm (BMI: 22.5)'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '5. Lab & Test Results',
                  items: [
                    _infoRow(context, 'Blood Tests', 'CBC: Normal, Sugar: 5.5 mmol/L'), // Hardcoded
                    _infoRow(context, 'Imaging', 'Chest X-ray: Clear'), // Hardcoded
                    _infoRow(context, 'ECG', 'Normal sinus rhythm'), // Hardcoded
                    _infoRow(context, 'Biopsy Reports', 'N/A'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '6. Recent Visit Notes',
                  items: [
                    _infoRow(context, 'Last Visit Date', _currentPatient!.lastVisit),
                    _infoRow(context, 'Notes', _currentPatient!.notes.join('\n')),
                    _infoRow(context, 'Symptoms', 'Shortness of breath, fatigue'), // Hardcoded
                    _infoRow(context, 'Physical Exam', 'Lungs clear, BP stable'), // Hardcoded
                    _infoRow(context, 'Diagnosis', 'Mild asthma attack'), // Hardcoded
                    _infoRow(context, 'Treatment', 'Inhaler, Rest'), // Hardcoded
                    _infoRow(context, 'Doctor\'s Notes', 'Follow-up in 2 weeks'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '7. Mental & Social Health',
                  items: [
                    _infoRow(context, 'Mental Health', 'Mild anxiety'), // Hardcoded
                    _infoRow(context, 'Lifestyle', 'Non-smoker, Occasional alcohol'), // Hardcoded
                    _infoRow(context, 'Support System', 'Lives with spouse, 2 kids'), // Hardcoded
                    _infoRow(context, 'Occupation', 'Teacher, moderate stress'), // Hardcoded
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '8. Progress Notes',
                  items: [
                    _infoRow(context, 'Response to Treatment', 'Improving, less wheezing'), // Hardcoded
                    _infoRow(context, 'Next Visit', '10 July 2025'), // Hardcoded
                    _infoRow(context, 'Complications', 'None'), // Hardcoded
                  ],
                ),
                const SizedBox(height: 24),

                // Nurse-specific action buttons for patient profile
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPatientScreen(patient: _currentPatient!),
                          ),
                        ).then((_) {
                          _fetchPatientData();
                        });
                        print('Edit Patient Profile for ${_currentPatient!.name}');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientMedicalRecordsScreen(
                              patientId: _currentPatient!.id, // Pass patient ID
                              patientName: _currentPatient!.name, // Pass patient name
                            ),
                          ),
                        );
                        print('View Medical Records for ${_currentPatient!.name}');
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Medical Records'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientPrescriptionsScreen(patientName: _currentPatient!.name),
                          ),
                        );
                        print('View Prescriptions for ${_currentPatient!.name}');
                      },
                      icon: const Icon(Icons.medication),
                      label: const Text('Prescriptions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientNotesScreen(patientName: _currentPatient!.name),
                          ),
                        );
                        print('View/Add Notes for ${_currentPatient!.name}');
                      },
                      icon: const Icon(Icons.notes),
                      label: const Text('Notes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text(
                'Get Directions to Patient',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening map directions...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Patient patient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.teal[300],
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            patient.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${patient.id} | ${patient.gender}, ${patient.age}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact: ${patient.contact}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required BuildContext context, required String title, required List<Widget> items}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800])),
            const SizedBox(height: 10),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Expanded(
              flex: 5,
              child: Text(value,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14))),
        ],
      ),
    );
  }
}
