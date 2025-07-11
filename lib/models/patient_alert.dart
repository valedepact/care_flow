import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Color

enum AlertStatus {
  active,
  acknowledged,
  dismissed,
  expired,
}

class PatientAlert {
  final String id;
  final String patientId;
  final String? patientName; // Can be null if the alert is for a nurse, but for patient view, it's their own name
  final String description;
  final String alertType; // e.g., "Medication Alert", "Appointment Reminder", "General Reminder"
  final DateTime scheduledDateTime;
  final AlertStatus status;
  final String? createdBy; // UID of the user who created the alert
  final String? createdByName; // Name of the user who created the alert

  PatientAlert({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.description,
    required this.alertType,
    required this.scheduledDateTime,
    this.status = AlertStatus.active,
    this.createdBy,
    this.createdByName,
  });

  // Factory constructor to create a PatientAlert from a Firestore DocumentSnapshot
  factory PatientAlert.fromFirestore(Map<String, dynamic> data, String id) {
    return PatientAlert(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'],
      description: data['description'] ?? 'No description',
      alertType: data['alertType'] ?? 'General Reminder',
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp).toDate(),
      status: AlertStatus.values.firstWhere(
            (e) => e.toString().split('.').last == (data['isAcknowledged'] == true ? 'acknowledged' : (data['status'] ?? 'active')),
        orElse: () => AlertStatus.active,
      ),
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
    );
  }

  // Method to convert PatientAlert object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'description': description,
      'alertType': alertType,
      'scheduledDateTime': scheduledDateTime,
      'status': status.toString().split('.').last, // Store as string
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  // Helper to get color based on alert status
  Color getStatusColor() {
    switch (status) {
      case AlertStatus.active:
        return Colors.blue.shade400;
      case AlertStatus.acknowledged:
        return Colors.green.shade400;
      case AlertStatus.dismissed:
        return Colors.grey.shade400;
      case AlertStatus.expired:
        return Colors.orange.shade400;
      default:
        return Colors.grey;
    }
  }
}
