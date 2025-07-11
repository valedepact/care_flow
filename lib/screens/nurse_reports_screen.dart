import 'package:flutter/material.dart';

class NurseReportsScreen extends StatelessWidget {
  const NurseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview of Patient Care',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            _buildReportCard(
              context,
              title: 'Patient Visit Summary (Last 30 Days)',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Total Visits', '50'),
                  _reportRow('Completed Visits', '45 (90%)'),
                  _reportRow('Missed Visits', '5 (10%)'),
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Consistent visit completion rate.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Visit Completion Rate Chart',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              title: 'Medication Adherence Overview',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Patients on Medication', '15'),
                  _reportRow('High Adherence (>80%)', '12'),
                  _reportRow('Moderate Adherence (50-80%)', '2'),
                  _reportRow('Low Adherence (<50%)', '1'),
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Generally good adherence, one patient requires closer monitoring.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Adherence Rate Chart',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              title: 'Vital Signs Trends (Selected Patients)',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Patient John Kelly', 'BP: Stable, HR: Slight increase'),
                  _reportRow('Patient Anna Davis', 'Temp: Normal, O2 Sat: 98%'),
                  const SizedBox(height: 10),
                  Text(
                    'Trend: Most vitals within normal range. Monitor John Kelly\'s heart rate.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  // Placeholder for a chart
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Text(
                      'Placeholder for Vital Signs Trend Graph',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              context,
              title: 'Overall Patient Status Summary',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reportRow('Stable Patients', '20'),
                  _reportRow('Improving Patients', '3'),
                  _reportRow('Critical Patients', '2'),
                  const SizedBox(height: 10),
                  Text(
                    'Action: Focus on critical patients and those requiring closer monitoring.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, {required String title, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            content,
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
