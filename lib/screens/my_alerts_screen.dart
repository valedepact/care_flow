import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart'; // For date formatting

// A simple model for an Alert, mirroring Firestore structure
class Alert {
  final String id;
  final String description;
  final String? patientId;
  final String? patientName;
  final String recipientRole;
  final String alertType;
  final DateTime scheduledDateTime;
  bool isAcknowledged; // Can be changed
  final DateTime createdAt;
  final String createdBy;

  Alert({
    required this.id,
    required this.description,
    this.patientId,
    this.patientName,
    required this.recipientRole,
    required this.alertType,
    required this.scheduledDateTime,
    this.isAcknowledged = false,
    required this.createdAt,
    required this.createdBy,
  });

  // Factory constructor to create an Alert from a Firestore DocumentSnapshot
  factory Alert.fromFirestore(Map<String, dynamic> data, String id) {
    return Alert(
      id: id,
      description: data['description'] ?? 'No description',
      patientId: data['patientId'],
      patientName: data['patientName'],
      recipientRole: data['recipientRole'] ?? 'Unknown',
      alertType: data['alertType'] ?? 'General Reminder',
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp).toDate(),
      isAcknowledged: data['isAcknowledged'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? 'Unknown',
    );
  }

  // Method to convert Alert object to a map for Firestore (for updates)
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'patientId': patientId,
      'patientName': patientName,
      'recipientRole': recipientRole,
      'alertType': alertType,
      'scheduledDateTime': scheduledDateTime,
      'isAcknowledged': isAcknowledged,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  List<Alert> _alerts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchAlerts();
  }

  Future<void> _initializeUserAndFetchAlerts() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserRole = userDoc.get('role');
        await _fetchAlerts();
      } else {
        setState(() {
          _errorMessage = 'User profile not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing user data: $e');
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      Query query = FirebaseFirestore.instance.collection('alerts');

      if (_currentUserRole == 'Patient') {
        // Patients see alerts specifically for them
        query = query.where('recipientRole', isEqualTo: 'Patient')
            .where('patientId', isEqualTo: _currentUser!.uid);
      } else if (_currentUserRole == 'Nurse') {
        // Nurses see alerts for patients they manage (if implemented)
        // For now, nurses see all alerts directed to 'Nurse' role,
        // and potentially all patient-specific alerts created by them or for their patients.
        // This logic can be refined later based on patient assignments.
        query = query.where('recipientRole', isEqualTo: 'Nurse')
            .orderBy('scheduledDateTime', descending: false); // Order for nurses
      } else {
        // Default or other roles might see general alerts or none
        setState(() {
          _errorMessage = 'No alerts configured for your role.';
          _isLoading = false;
        });
        return;
      }

      QuerySnapshot snapshot = await query.get();

      List<Alert> fetchedAlerts = snapshot.docs.map((doc) {
        return Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // For patients, also show general reminders not tied to a specific patientId
      if (_currentUserRole == 'Patient') {
        QuerySnapshot generalAlertsSnapshot = await FirebaseFirestore.instance
            .collection('alerts')
            .where('recipientRole', isEqualTo: 'Patient')
            .where('patientId', isNull: true) // General alerts for all patients
            .orderBy('scheduledDateTime', descending: false)
            .get();
        fetchedAlerts.addAll(generalAlertsSnapshot.docs.map((doc) {
          return Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }));
      }

      // Sort alerts by scheduledDateTime
      fetchedAlerts.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      if (mounted) {
        setState(() {
          _alerts = fetchedAlerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading alerts: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAcknowledge(Alert alert) async {
    setState(() {
      alert.isAcknowledged = !alert.isAcknowledged; // Optimistic update
    });
    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(alert.id)
          .update({'isAcknowledged': alert.isAcknowledged});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alert.isAcknowledged ? 'Alert acknowledged!' : 'Alert unacknowledged.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating alert status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update alert status: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          alert.isAcknowledged = !alert.isAcknowledged; // Revert optimistic update
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alerts'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlerts, // Refresh alerts
            tooltip: 'Refresh Alerts',
          ),
        ],
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
        child: Text('No alerts found.'),
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
            color: alert.isAcknowledged ? Colors.grey.shade200 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForAlertType(alert.alertType),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.alertType,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          alert.isAcknowledged ? 'ACKNOWLEDGED' : 'PENDING',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: alert.isAcknowledged ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For: ${alert.recipientRole}${alert.patientName != null ? ' (${alert.patientName})' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                  Text(
                    'Scheduled: ${DateFormat('MMM d, yyyy - h:mm a').format(alert.scheduledDateTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                  Text(
                    'Created: ${DateFormat('MMM d, yyyy').format(alert.createdAt)} by ${alert.createdBy == FirebaseAuth.instance.currentUser?.uid ? 'You' : alert.createdBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleAcknowledge(alert),
                      icon: Icon(alert.isAcknowledged ? Icons.check_circle : Icons.circle_outlined),
                      label: Text(alert.isAcknowledged ? 'Unacknowledge' : 'Acknowledge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alert.isAcknowledged ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  IconData _getIconForAlertType(String alertType) {
    switch (alertType) {
      case 'Visit Reminder':
        return Icons.calendar_today;
      case 'Medication Alert':
        return Icons.medication;
      case 'Activity Reminder':
        return Icons.directions_run;
      case 'Emergency Alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications;
    }
  }
}
