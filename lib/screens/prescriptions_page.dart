import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/prescription.dart'; // Import the Prescription model
// For debugPrint

class PrescriptionsPage extends StatefulWidget {
  final String patientId; // Required patientId
  final String patientName; // Required patientName for display

  const PrescriptionsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  List<Prescription> _prescriptions = []; // Now a dynamic list of Prescription objects
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
        title: Text('${widget.patientName}\'s Prescriptions'), // Use patientName in title
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
                    prescription.medicationName, // Use medicationName from model
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Dosage', prescription.dosage),
                  _buildInfoRow(context, 'Frequency', prescription.frequency),
                  _buildInfoRow(context, 'Prescribed By', prescription.prescribedBy),
                  _buildInfoRow(context, 'Prescribed Date', DateFormat('MMM d, yyyy').format(prescription.prescribedDate)),
                  if (prescription.endDate != null)
                    _buildInfoRow(context, 'End Date', DateFormat('MMM d, yyyy').format(prescription.endDate!)),
                  // Status is not directly in the model, you might infer it or add a field
                  // For now, we'll use a dummy status or infer from endDate
                  _buildInfoRow(context, 'Status', (prescription.endDate != null && prescription.endDate!.isBefore(DateTime.now())) ? 'Completed' : 'Active'),
                  if (prescription.notes.isNotEmpty)
                    _buildInfoRow(context, 'Notes', prescription.notes),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate refill request
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Refill request sent for ${prescription.medicationName}!')),
                        );
                        debugPrint('Refill requested for ${prescription.medicationName}'); // Changed print to debugPrint
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

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
