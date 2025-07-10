import 'package:flutter/material.dart';

class PatientProfilePage extends StatelessWidget {
  final String patientName;

  const PatientProfilePage({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$patientName\'s Profile'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: Image.network(
                  'https://placehold.co/120x120/A7D9FF/007BFF?text=P', // Placeholder for patient image
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_outline,
                    size: 120,
                    color: Colors.grey,
                  ),
                ).image,
                backgroundColor: Colors.blue.shade100,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                patientName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Patient ID: P123456', // Placeholder ID
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Divider(),
            _buildInfoRow(context, Icons.phone, 'Phone', '+1 (555) 123-4567'),
            _buildInfoRow(context, Icons.email, 'Email', 'patient@example.com'),
            _buildInfoRow(context, Icons.home, 'Address', '123 Main St, Anytown, USA'),
            const SizedBox(height: 32),

            Text(
              'Medical Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Divider(),
            _buildInfoRow(context, Icons.calendar_today, 'Date of Birth', '1990-05-15'),
            _buildInfoRow(context, Icons.wc, 'Gender', 'Female'),
            _buildInfoRow(context, Icons.medical_information, 'Blood Type', 'O+'),
            _buildInfoRow(context, Icons.sick, 'Known Conditions', 'Hypertension, Type 2 Diabetes'),
            _buildInfoRow(context, Icons.warning, 'Allergies', 'Penicillin'),
            _buildInfoRow(context, Icons.medication, 'Current Medications', 'Metformin, Lisinopril'),
            const SizedBox(height: 32),

            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Divider(),
            // Placeholder for a list of recent activities/visits
            ListTile(
              leading: const Icon(Icons.event_note, color: Colors.grey),
              title: const Text('Last Visit: July 1, 2025 - General Check-up'),
              subtitle: const Text('Dr. Alex Smith'),
              onTap: () {
                print('View last visit details');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.grey),
              title: const Text('Last Prescription Refill: June 20, 2025'),
              subtitle: const Text('Insulin'),
              onTap: () {
                print('View prescription details');
              },
            ),
            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Action to edit patient profile
                  print('Edit Patient Profile for $patientName');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
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
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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
}
