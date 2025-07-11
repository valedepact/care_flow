import 'package:flutter/material.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  // Dummy data for prescriptions
  final List<Map<String, String>> _prescriptions = const [
    {
      'medication': 'Metformin',
      'dosage': '500 mg',
      'frequency': 'Twice daily',
      'prescribedBy': 'Dr. Emily White',
      'refillDate': '2025-08-01',
      'status': 'Active',
      'notes': 'Take with food.',
    },
    {
      'medication': 'Ventolin HFA (Albuterol)',
      'dosage': '2 puffs',
      'frequency': 'As needed for asthma symptoms',
      'prescribedBy': 'Dr. Alex Smith',
      'refillDate': '2025-09-15',
      'status': 'Active',
      'notes': 'Shake well before use.',
    },
    {
      'medication': 'Lisinopril',
      'dosage': '10 mg',
      'frequency': 'Once daily',
      'prescribedBy': 'Dr. Emily White',
      'refillDate': '2025-07-05',
      'status': 'Active (Due for Refill)',
      'notes': 'For hypertension.',
    },
    {
      'medication': 'Amoxicillin',
      'dosage': '250 mg',
      'frequency': 'Three times daily',
      'prescribedBy': 'Dr. Sarah Green',
      'refillDate': '2025-06-10',
      'status': 'Completed',
      'notes': 'For bacterial infection. Course finished.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _prescriptions.isEmpty
          ? const Center(
        child: Text('You have no active prescriptions.'),
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
                    prescription['medication']!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Dosage', prescription['dosage']!),
                  _buildInfoRow(context, 'Frequency', prescription['frequency']!),
                  _buildInfoRow(context, 'Prescribed By', prescription['prescribedBy']!),
                  _buildInfoRow(context, 'Refill Date', prescription['refillDate']!),
                  _buildInfoRow(context, 'Status', prescription['status']!),
                  if (prescription['notes']!.isNotEmpty)
                    _buildInfoRow(context, 'Notes', prescription['notes']!),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulate refill request
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Refill request sent for ${prescription['medication']}!')),
                        );
                        print('Refill requested for ${prescription['medication']}');
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
