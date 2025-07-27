import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:care_flow/models/alert_model.dart'; // Import the Alert model
import 'dart:async'; // Import for StreamSubscription
import 'package:hive/hive.dart';

class NurseAlertsScreen extends StatefulWidget {
  const NurseAlertsScreen({super.key});

  @override
  State<NurseAlertsScreen> createState() => _NurseAlertsScreenState();
}

class _NurseAlertsScreenState extends State<NurseAlertsScreen> {
  User? _currentUser;
  String? _errorMessage;
  Set<String> _assignedPatientIds = {}; // To store UIDs of patients assigned to this nurse

  // Stream subscriptions for alerts from both collections
  StreamSubscription? _generalAlertsSubscription;
  StreamSubscription? _emergencyAlertsSubscription;

  // List to hold combined alerts
  List<Alert> _combinedAlerts = [];
  bool _isLoadingAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in. Cannot fetch alerts.';
          _isLoadingAlerts = false;
        });
      }
      return;
    }

    // 1. Load from Hive first
    var alertBox = Hive.box<Alert>('alerts');
    setState(() {
      _combinedAlerts = alertBox.values.toList();
      _isLoadingAlerts = false;
    });

    try {
      // Fetch all patients assigned to the current nurse
      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: _currentUser!.uid)
          .get();

      if (!mounted) return;

      Set<String> patientIds = {};
      for (var doc in patientSnapshot.docs) {
        patientIds.add(doc.id);
      }

      setState(() {
        _assignedPatientIds = patientIds;
        _errorMessage = null;
      });

      if (_assignedPatientIds.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'You are not assigned to any patients. No alerts to display.';
            _isLoadingAlerts = false;
          });
        }
        return;
      }

      // Fetch alerts from Firestore
      QuerySnapshot generalSnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('patientId', whereIn: _assignedPatientIds.toList())
          .where('status', whereIn: ['active', 'critical', 'info', 'pending'])
          .orderBy('timestamp', descending: true)
          .get();

      QuerySnapshot emergencySnapshot = await FirebaseFirestore.instance
          .collection('emergencyAlerts')
          .where('patientId', whereIn: _assignedPatientIds.toList())
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      List<Alert> alerts = [];
      for (var doc in generalSnapshot.docs) {
        alerts.add(Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      for (var doc in emergencySnapshot.docs) {
        alerts.add(Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Update Hive
      await alertBox.clear();
      await alertBox.addAll(alerts);

      if (mounted) {
        setState(() {
          _combinedAlerts = alerts;
          _isLoadingAlerts = false;
        });
      }
    } catch (e) {
      debugPrint('NurseAlertsScreen: Error fetching alerts: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load alerts: $e';
          _isLoadingAlerts = false;
        });
      }
    }
  }

  void _listenToAlertStreams() {
    if (_currentUser == null || _assignedPatientIds.isEmpty) return;

    _generalAlertsSubscription?.cancel();
    _emergencyAlertsSubscription?.cancel();

    // Initial load state
    setState(() {
      _isLoadingAlerts = true;
      _errorMessage = '';
    });
    debugPrint('NurseAlertsScreen: Starting to listen to alert streams for UID: ${_currentUser!.uid}');

    // Listen to alerts from the 'alerts' collection
    _generalAlertsSubscription = FirebaseFirestore.instance
        .collection('alerts')
        .where('patientId', whereIn: _assignedPatientIds.toList())
        .where('status', whereIn: ['active', 'critical', 'info', 'pending']) // Include all relevant statuses
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _processAlertSnapshots(); // Trigger combined processing
    }, onError: (e) {
      debugPrint('NurseAlertsScreen: Stream error (general alerts): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading general alerts: $e';
          _isLoadingAlerts = false;
        });
      }
    });

    // Listen to alerts from the 'emergencyAlerts' collection
    _emergencyAlertsSubscription = FirebaseFirestore.instance
        .collection('emergencyAlerts')
        .where('patientId', whereIn: _assignedPatientIds.toList())
        .where('status', isEqualTo: 'pending') // Emergency alerts start as 'pending'
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _processAlertSnapshots(); // Trigger combined processing
    }, onError: (e) {
      debugPrint('NurseAlertsScreen: Stream error (emergency alerts): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading emergency alerts: $e';
          _isLoadingAlerts = false;
        });
      }
    });
  }

  // Combine and process alerts from both streams
  void _processAlertSnapshots() async {
    List<Alert> alerts = [];

    // Fetch current snapshots (ensure they are available)
    // Using get() here to combine, as direct stream merging is more complex
    QuerySnapshot? generalSnapshot;
    QuerySnapshot? emergencySnapshot;

    try {
      if (_assignedPatientIds.isNotEmpty) {
        generalSnapshot = await FirebaseFirestore.instance
            .collection('alerts')
            .where('patientId', whereIn: _assignedPatientIds.toList())
            .where('status', whereIn: ['active', 'critical', 'info', 'pending'])
            .orderBy('timestamp', descending: true)
            .get();

        emergencySnapshot = await FirebaseFirestore.instance
            .collection('emergencyAlerts')
            .where('patientId', whereIn: _assignedPatientIds.toList())
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .get();
      }
    } catch (e) {
      debugPrint('NurseAlertsScreen: Error fetching snapshots for combined processing: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error combining alerts: $e';
          _isLoadingAlerts = false;
        });
      }
      return;
    }


    if (!mounted) return;

    // Process general alerts
    if (generalSnapshot != null) {
      for (var doc in generalSnapshot.docs) {
        alerts.add(Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
    }


    // Process emergency alerts
    if (emergencySnapshot != null) {
      for (var doc in emergencySnapshot.docs) {
        alerts.add(Alert.fromFirestore(doc.data() as Map<String, dynamic>, doc.id));
      }
    }


    // Sort all alerts by timestamp (most recent first)
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _combinedAlerts = alerts;
        _isLoadingAlerts = false;
      });
      debugPrint('NurseAlertsScreen: _combinedAlerts updated. Total alerts: ${_combinedAlerts.length}');
    }
  }

  Future<void> _dismissAlert(String alertId, String collectionName) async {
    final currentContext = context;
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(alertId).update({
        'status': 'dismissed', // Use string 'dismissed'
      });
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Alert dismissed.')),
        );
      }
    } catch (e) {
      debugPrint('NurseAlertsScreen: Error dismissing alert from $collectionName: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to dismiss alert: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Alerts'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage ?? 'Please log in to view patient alerts.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Alerts'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (_isLoadingAlerts) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Alerts'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_combinedAlerts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Alerts'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: const Center(child: Text('No active alerts from your assigned patients.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Alerts'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _combinedAlerts.length,
        itemBuilder: (context, index) {
          final alert = _combinedAlerts[index];
          // Determine the collection name for dismissal (assuming it's either 'alerts' or 'emergencyAlerts')
          // This is a simplification; in a real app, you might store the collection name in the Alert model
          // or derive it based on alert.type. For now, we'll assume 'emergencyAlerts' if type is 'emergency'
          // otherwise 'alerts'.
          final String collectionToDismissFrom = alert.type == 'emergency' ? 'emergencyAlerts' : 'alerts';

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
                      Expanded(
                        child: Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Alert.getColorForStatus(alert.status), // Use dynamic color
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Alert.getColorForStatus(alert.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alert.status.toUpperCase(), // Display status as string
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Patient: ${alert.patientName ?? 'Unknown Patient'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From: ${alert.createdByUserName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(alert.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                  if (alert.status != 'dismissed') // Only show dismiss button if not already dismissed
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton.icon(
                        onPressed: () => _dismissAlert(alert.id, collectionToDismissFrom),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Dismiss Alert'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
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
}
