import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/medical_record.dart'; // Import the new MedicalRecord model

class PatientMedicalRecordsScreen extends StatefulWidget {
  final String patientId; // Now requires patientId
  final String patientName; // For display purposes

  const PatientMedicalRecordsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientMedicalRecordsScreen> createState() => _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState extends State<PatientMedicalRecordsScreen> {
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMedicalRecords();
  }

  Future<void> _fetchMedicalRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('medicalRecords')
          .where('patientId', isEqualTo: widget.patientId) // Filter by patient ID
          .orderBy('recordDate', descending: true) // Show most recent records first
          .get();

      if (!mounted) return; // Check mounted after await

      List<MedicalRecord> fetchedRecords = snapshot.docs.map((doc) {
        return MedicalRecord.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _medicalRecords = fetchedRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching medical records: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading medical records: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Medical Records'),
        backgroundColor: Colors.indigo.shade700,
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
          : _medicalRecords.isEmpty
          ? Center(
        child: Text('No medical records found for ${widget.patientName}.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _medicalRecords.length,
        itemBuilder: (context, index) {
          final record = _medicalRecords[index];
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
                  Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${record.type}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(record.recordDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (record.doctorName != null && record.doctorName!.isNotEmpty)
                    Text(
                      'Doctor: ${record.doctorName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    record.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (record.fileUrl != null && record.fileUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton.icon(
                        onPressed: () {
                          // Implement logic to open fileUrl (e.g., using url_launcher package)
                          print('Opening file: ${record.fileUrl}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening file from URL: ${record.fileUrl}')),
                          );
                        },
                        icon: const Icon(Icons.attachment),
                        label: const Text('View Attachment'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement Add Medical Record functionality
          print('Add New Medical Record for ${widget.patientName}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Medical Record functionality coming soon!')),
          );
        },
        label: const Text('Add Record'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
