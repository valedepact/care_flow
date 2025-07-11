import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class EmergencyAlertsPage extends StatefulWidget {
  const EmergencyAlertsPage({super.key});

  @override
  State<EmergencyAlertsPage> createState() => _EmergencyAlertsPageState();
}

class _EmergencyAlertsPageState extends State<EmergencyAlertsPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSendingAlert = false;
  String _patientName = 'Patient';
  String _patientId = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              _patientName = userDoc.get('fullName') ?? 'Patient';
              _patientId = currentUser.uid;
            });
          }
        } else {
          print('Patient document not found for UID: ${currentUser.uid}');
        }
      } catch (e) {
        print('Error fetching patient data for emergency alert: $e');
      }
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message for the alert.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient ID not available. Cannot send alert.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSendingAlert = true;
    });

    try {
      // Create the alert data
      Map<String, dynamic> alertData = {
        'patientId': _patientId,
        'patientName': _patientName,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
        'status': 'pending', // e.g., pending, resolved
        'type': 'emergency', // Differentiate from other alerts
        'acknowledgedBy': null, // To be filled by a nurse/doctor
      };

      // Add the alert to a dedicated 'emergencyAlerts' collection
      await FirebaseFirestore.instance.collection('emergencyAlerts').add(alertData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent successfully! Your care team has been notified.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _messageController.clear();
      }
    } catch (e) {
      print('Error sending emergency alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send emergency alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Send Emergency Alert',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use this feature ONLY in a real emergency. Your care team will be immediately notified.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Describe your emergency (Optional but Recommended)',
                hintText: 'e.g., "Severe chest pain", "Difficulty breathing", "Fallen and cannot get up"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: _isSendingAlert
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _sendEmergencyAlert,
                icon: const Icon(Icons.send),
                label: const Text('SEND EMERGENCY ALERT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
