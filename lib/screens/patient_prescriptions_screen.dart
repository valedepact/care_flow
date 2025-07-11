import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/prescription.dart'; // Import the new Prescription model
// For debugPrint

class PatientPrescriptionsScreen extends StatefulWidget {
  final String patientId; // Now requires patientId
  final String patientName; // For display purposes

  const PatientPrescriptionsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends State<PatientPrescriptionsScreen> {
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: widget.patientId) // Filter by patient ID
          .orderBy('prescribedDate', descending: true) // Show most recent prescriptions first
          .get();

      List<Prescription> fetchedPrescriptions = snapshot.docs.map((doc) {
        return Prescription.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _prescriptions = fetchedPrescriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e'); // Changed print to debugPrint
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading prescriptions: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Prescriptions'),
        backgroundColor: Colors.purple.shade700,
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
          : _prescriptions.isEmpty
          ? Center(
        child: Text('No prescriptions found for ${widget.patientName}.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = _prescriptions[index];
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
                    prescription.medicationName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dosage: ${prescription.dosage}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Frequency: ${prescription.frequency}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Prescribed Date: ${DateFormat('MMM d, yyyy').format(prescription.prescribedDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (prescription.endDate != null)
                    Text(
                      'End Date: ${DateFormat('MMM d, yyyy').format(prescription.endDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  Text(
                    'Prescribed By: ${prescription.prescribedBy}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (prescription.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes: ${prescription.notes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // Implement logic to view/manage prescription details
                        debugPrint('View/Manage Prescription ID: ${prescription.id}'); // Changed print to debugPrint
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing details for ${prescription.medicationName}')),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement Add Prescription functionality
          debugPrint('Add New Prescription for ${widget.patientName}'); // Changed print to debugPrint
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Prescription functionality coming soon!')),
          );
        },
        label: const Text('Add Prescription'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
