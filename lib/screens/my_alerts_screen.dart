import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/patient_alert.dart'; // Import the new PatientAlert model

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  List<PatientAlert> _patientAlerts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPatientAlerts();
  }

  Future<void> _fetchPatientAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in. Cannot fetch alerts.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch alerts where the patientId matches the current user's UID
      // OR where recipientRole is 'Patient' and patientId is current user's UID
      // For simplicity, we'll assume alerts directly linked via patientId for now.
      // A more complex query might be needed for alerts targeting 'Patient' role generally.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('patientId', isEqualTo: _currentUser!.uid)
          .orderBy('scheduledDateTime', descending: true) // Show most recent alerts first
          .get();

      List<PatientAlert> fetchedAlerts = snapshot.docs.map((doc) {
        return PatientAlert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _patientAlerts = fetchedAlerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patient alerts: $e');
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
        'isAcknowledged': newStatus == AlertStatus.acknowledged, // Update isAcknowledged for backward compatibility
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert status updated to ${newStatus.toString().split('.').last}!')),
        );
        _fetchPatientAlerts(); // Refresh the list
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
        title: const Text('My Alerts'),
        backgroundColor: Colors.deepPurple.shade700,
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
          : _patientAlerts.isEmpty
          ? const Center(
        child: Text('You have no alerts or reminders.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _patientAlerts.length,
        itemBuilder: (context, index) {
          final alert = _patientAlerts[index];
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
                  if (alert.status == AlertStatus.active)
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
