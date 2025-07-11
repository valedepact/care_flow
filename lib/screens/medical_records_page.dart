import 'package:flutter/material.dart';

class MedicalRecordsPage extends StatelessWidget {
  // In a real application, you would pass a patient ID here
  // and fetch the actual medical records from a backend.
  const MedicalRecordsPage({super.key});

  // Dummy data for medical records
  final Map<String, List<Map<String, String>>> _medicalRecords = const {
    'Recent Lab Results': [
      {'Date': '2025-07-01', 'Test': 'Complete Blood Count (CBC)', 'Result': 'Normal'},
      {'Date': '2025-06-15', 'Test': 'Blood Glucose', 'Result': '5.5 mmol/L (Normal)'},
      {'Date': '2025-05-20', 'Test': 'Cholesterol Panel', 'Result': 'LDL: 100 mg/dL (Normal), HDL: 55 mg/dL (Normal)'},
    ],
    'Imaging Reports': [
      {'Date': '2025-06-25', 'Type': 'Chest X-ray', 'Finding': 'No acute cardiopulmonary abnormality.'},
      {'Date': '2024-11-10', 'Type': 'Abdominal Ultrasound', 'Finding': 'Normal study.'},
    ],
    'Vaccination History': [
      {'Date': '2024-10-01', 'Vaccine': 'Influenza', 'Dose': 'Annual'},
      {'Date': '2021-03-01', 'Vaccine': 'COVID-19 (Pfizer)', 'Dose': '2nd Dose'},
      {'Date': '2021-02-01', 'Vaccine': 'COVID-19 (Pfizer)', 'Dose': '1st Dose'},
      {'Date': '2015-08-01', 'Vaccine': 'Tetanus, Diphtheria, Pertussis (Tdap)', 'Dose': 'Booster'},
    ],
    'Allergies': [
      {'Allergen': 'Penicillin', 'Reaction': 'Rash, Hives'},
      {'Allergen': 'Dust Mites', 'Reaction': 'Sneezing, Runny Nose'},
    ],
    'Chronic Conditions': [
      {'Condition': 'Hypertension', 'Diagnosis Date': '2020-01-10', 'Status': 'Controlled'},
      {'Condition': 'Asthma', 'Diagnosis Date': '2010-05-01', 'Status': 'Well-controlled'},
    ],
    'Past Surgeries': [
      {'Date': '2018-07-20', 'Procedure': 'Appendectomy', 'Hospital': 'City General Hospital'},
    ],
    'Medication History': [
      {'Medication': 'Metformin', 'Dosage': '500mg BID', 'Prescribed By': 'Dr. Emily'},
      {'Medication': 'Ventolin Inhaler', 'Dosage': 'As needed', 'Prescribed By': 'Dr. Alex Smith'},
      {'Medication': 'Lisinopril', 'Dosage': '10mg Daily', 'Prescribed By': 'Dr. Emily'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _medicalRecords.entries.map((entry) {
            return _buildRecordSection(
              context,
              title: entry.key,
              records: entry.value,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecordSection(BuildContext context, {required String title, required List<Map<String, String>> records}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
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
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            records.isEmpty
                ? Text(
              'No $title records found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            )
                : Column(
              children: records.map((record) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: record.entries.map((item) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.key}: ',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Expanded(
                            child: Text(
                              item.value,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
