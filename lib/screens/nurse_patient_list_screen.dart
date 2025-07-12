import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current nurse's UID
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/screens/patient_profile_page.dart'; // Import PatientProfilePage

class NursePatientListScreen extends StatefulWidget {
  const NursePatientListScreen({super.key});

  @override
  State<NursePatientListScreen> createState() => _NursePatientListScreenState();
}

class _NursePatientListScreenState extends State<NursePatientListScreen> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentNurseId; // To store the logged-in nurse's UID

  @override
  void initState() {
    super.initState();
    _getCurrentNurseIdAndFetchPatients(); // Combined method
  }

  // Get the current nurse's UID and then fetch their patients
  Future<void> _getCurrentNurseIdAndFetchPatients() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentNurseId = user.uid;
      debugPrint('Current Nurse ID for patient list: $_currentNurseId');
      _fetchPatients(); // Fetch patients once nurse ID is available
    } else {
      debugPrint('No nurse user logged in. Cannot fetch patients.');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in as a nurse to view your patients.';
        });
      }
    }
  }

  Future<void> _fetchPatients() async {
    if (_currentNurseId == null) {
      debugPrint('Nurse ID is null, cannot fetch patients.');
      return; // Should not happen if _getCurrentNurseIdAndFetchPatients is called correctly
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // *** IMPORTANT CHANGE HERE: Filter patients by nurseId ***
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: _currentNurseId) // Filter by current nurse's ID
          .snapshots() // Use snapshots for real-time updates
          .first; // Get the first snapshot to convert to Future

      if (!mounted) return; // Check mounted after await

      List<Patient> fetchedPatients = snapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _patients = fetchedPatients;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e'); // Use debugPrint
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading patients: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
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
          : _patients.isEmpty
          ? const Center(
        child: Text('You have not claimed any patients yet. Go to "Patient Management" to claim patients.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to PatientProfilePage, passing the patient ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientProfilePage(
                      patientId: patient.id,
                      patientName: patient.name, // Pass name for initial display
                    ),
                  ),
                ).then((_) {
                  // Refresh the patient list when returning from the profile/edit screen
                  _fetchPatients(); // Re-fetch patients to ensure updated list
                });
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${patient.id}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Condition: ${patient.condition.isNotEmpty ? patient.condition : 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Contact: ${patient.contact}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
