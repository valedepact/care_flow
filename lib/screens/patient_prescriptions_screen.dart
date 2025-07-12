import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/prescription.dart'; // Import the Prescription model
import 'package:care_flow/screens/add_prescription_screen.dart'; // Import the AddPrescriptionScreen

class PatientPrescriptionsScreen extends StatefulWidget {
  final String patientId; // Required patientId
  final String patientName; // Required patientName for display

  const PatientPrescriptionsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends State<PatientPrescriptionsScreen> {
  // Removed _prescriptions list, _isLoading, and _errorMessage as StreamBuilder will manage the data and errors
  // These were from the previous Future-based fetching logic.

  @override
  void initState() {
    super.initState();
    // No need to call _fetchPrescriptions here, StreamBuilder will handle it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Prescriptions'), // Use patientName in title
        backgroundColor: Colors.purple.shade700, // Consistent color for prescriptions
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>( // Using StreamBuilder for real-time updates
        stream: FirebaseFirestore.instance
            .collection('prescriptions')
            .where('patientId', isEqualTo: widget.patientId) // Filter by patient ID
            .orderBy('prescribedDate', descending: true) // Show most recent prescriptions first
            .snapshots(), // Use .snapshots() for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error fetching prescriptions stream: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading prescriptions: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No prescriptions found for ${widget.patientName}.'),
            );
          }

          // Map the fetched documents to Prescription objects
          final prescriptions = snapshot.data!.docs.map((doc) {
            return Prescription.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = prescriptions[index];
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
                        prescription.medicationName, // Use medicationName from model
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'Dosage', prescription.dosage),
                      _buildInfoRow(context, 'Frequency', prescription.frequency),
                      // Corrected to display prescribedByName from the model
                      _buildInfoRow(context, 'Prescribed By', prescription.prescribedByName),
                      _buildInfoRow(context, 'Prescribed Date', DateFormat('MMM d, yyyy').format(prescription.prescribedDate)),
                      if (prescription.endDate != null)
                        _buildInfoRow(context, 'End Date', DateFormat('MMM d, yyyy').format(prescription.endDate!)),
                      // Status is not directly in the model, you might infer it or add a field
                      _buildInfoRow(context, 'Status', (prescription.endDate != null && prescription.endDate!.isBefore(DateTime.now())) ? 'Completed' : 'Active'),
                      // Corrected to display instructions from the model
                      if (prescription.instructions.isNotEmpty)
                        _buildInfoRow(context, 'Instructions', prescription.instructions),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Simulate refill request
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Refill request sent for ${prescription.medicationName}!')),
                              );
                            }
                            debugPrint('Refill requested for ${prescription.medicationName}');
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Request Refill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Green for refill
                            foregroundColor: Colors.white,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Capture context before async gap
          final currentContext = context;
          // Navigate to AddPrescriptionScreen using its constructor
          Navigator.push(
            currentContext,
            MaterialPageRoute(
              builder: (context) => AddPrescriptionScreen(
                patientId: widget.patientId,
                patientName: widget.patientName,
              ),
            ),
          );
          debugPrint('Add New Prescription for ${widget.patientName}');
        },
        label: const Text('Add Prescription'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purple.shade700, // Consistent color for prescriptions
        foregroundColor: Colors.white,
      ),
    );
  }

  // Helper method to build info rows (kept as is from your provided code)
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
