import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/screens/patient_profile_page.dart'; // Import PatientProfilePage

class NursePatientListScreen extends StatefulWidget {
  final String nurseId; // IMPORTANT: This parameter is required for filtering

  const NursePatientListScreen({super.key, required this.nurseId}); // Constructor now requires nurseId

  @override
  State<NursePatientListScreen> createState() => _NursePatientListScreenState();
}

class _NursePatientListScreenState extends State<NursePatientListScreen> {
  // No need for _patients list, _isLoading, or _errorMessage here,
  // as StreamBuilder handles loading and data directly.

  @override
  void initState() {
    super.initState();
    // The nurseId is now passed via the widget, so no need to fetch it here.
    // StreamBuilder will handle fetching patients based on widget.nurseId.
  }

  @override
  Widget build(BuildContext context) {
    // The current nurse's ID is available via widget.nurseId
    // We can add a check here, though it should always be provided by CaregiverDashboard
    if (widget.nurseId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Claimed Patients'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Error: Nurse ID not provided. Please log in again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Claimed Patients'), // More specific title
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('nurseId', isEqualTo: widget.nurseId) // Filter by the nurseId passed to the widget
            .orderBy('name', descending: false) // Order by patient name
            .snapshots(), // Use .snapshots() for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching patients stream: ${snapshot.error}');
            return Center(child: Text('Error loading patients: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('You have not claimed any patients yet.'),
            );
          }

          final patients = snapshot.data!.docs.map((doc) {
            return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to PatientProfilePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientProfilePage(
                          patientId: patient.id,
                          patientName: patient.name,
                        ),
                      ),
                    );
                    debugPrint('Opening patient profile for ${patient.name} (ID: ${patient.id})');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Condition: ${patient.condition.isNotEmpty ? patient.condition : 'N/A'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'Age: ${patient.age}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Gender: ${patient.gender}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Contact: ${patient.contact}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // You can add more patient details here
                      ],
                    ),
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
