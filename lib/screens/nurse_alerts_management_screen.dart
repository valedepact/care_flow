import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/patient_alert.dart'; // Reusing PatientAlert model for alerts

class NurseAlertsManagementScreen extends StatefulWidget {
  const NurseAlertsManagementScreen({super.key});

  @override
  State<NurseAlertsManagementScreen> createState() => _NurseAlertsManagementScreenState();
}

class _NurseAlertsManagementScreenState extends State<NurseAlertsManagementScreen> {
  List<PatientAlert> _alerts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Fetch all alerts. In a real application, a nurse might only see alerts
      // assigned to their patients, or alerts they created, or only 'active' alerts.
      // For now, we fetch all and let the nurse manage.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('scheduledDateTime', descending: true) // Show most recent alerts first
          .get();

      List<PatientAlert> fetchedAlerts = snapshot.docs.map((doc) {
        return PatientAlert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _alerts = fetchedAlerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching alerts for nurse: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading alerts: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAlertStatus(String alertId, AlertStatus newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
        'status': newStatus.toString().split('.').last, // Store enum as string
        // For backward compatibility if 'isAcknowledged' was used before 'status' enum
        'isAcknowledged': newStatus == AlertStatus.acknowledged,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert status updated to ${newStatus.toString().split('.').last}!')),
        );
        _fetchAlerts(); // Refresh the list
      }
    } catch (e) {
      print('Error updating alert status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts Management'),
        backgroundColor: Colors.deepPurple.shade700, // Consistent color for alerts
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
          : _alerts.isEmpty
          ? const Center(
        child: Text('No alerts to manage.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.alertType,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: alert.getStatusColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alert.status.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (alert.patientName != null && alert.patientName!.isNotEmpty)
                    Text(
                      'Patient: ${alert.patientName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  Text(
                    alert.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled: ${DateFormat('MMM d, yyyy - h:mm a').format(alert.scheduledDateTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (alert.createdByName != null && alert.createdByName!.isNotEmpty)
                    Text(
                      'Created By: ${alert.createdByName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  if (alert.status == AlertStatus.active || alert.status == AlertStatus.expired)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Wrap(
                        spacing: 8.0,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateAlertStatus(alert.id, AlertStatus.acknowledged),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Acknowledge'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _updateAlertStatus(alert.id, AlertStatus.dismissed),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Dismiss'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
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
}
