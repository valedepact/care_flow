import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/medical_record.dart'; // Import the MedicalRecord model
// For debugPrint (already provided by material.dart or flutter/foundation.dart)

class MedicalRecordsPage extends StatefulWidget {
  final String patientId; // Now requires patientId
  final String patientName; // For display purposes

  const MedicalRecordsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  // Removed _medicalRecords list, _isLoading, and _errorMessage as StreamBuilder will manage the data and errors
  // String _errorMessage = ''; // No longer needed

  @override
  void initState() {
    super.initState();
    // No need to call _fetchMedicalRecords here, StreamBuilder will handle it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Medical Records'),
        backgroundColor: Colors.indigo.shade700, // Consistent color for medical records
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicalRecords')
            .where('patientId', isEqualTo: widget.patientId)
            .orderBy('recordDate', descending: true) // Show most recent records first
            .snapshots(), // Use .snapshots() for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching medical records stream: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading medical records: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No medical records found for ${widget.patientName}.'),
            );
          }

          // Map the fetched documents to MedicalRecord objects
          final medicalRecords = snapshot.data!.docs.map((doc) {
            return MedicalRecord.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: medicalRecords.length,
            itemBuilder: (context, index) {
              final record = medicalRecords[index];
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
                              // TODO: Implement logic to open fileUrl (e.g., using url_launcher package)
                              debugPrint('Opening file: ${record.fileUrl}');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening file from URL: ${record.fileUrl}')),
                                );
                              }
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement Add Medical Record functionality (e.g., show a dialog or navigate to a new screen)
          debugPrint('Add New Medical Record for ${widget.patientName}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Medical Record functionality coming soon!')),
            );
          }
        },
        label: const Text('Add Record'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
