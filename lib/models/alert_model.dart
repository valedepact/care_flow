import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:hive/hive.dart';
part 'alert_model.g.dart';

enum AlertStatus {
  active,
  dismissed,
  critical, // Example status
  info,     // Example status
  pending,  // NEW: For pending alerts from patients
}

@HiveType(typeId: 1)
class Alert extends HiveObject {
  @HiveField(0)
  final String id; // Document ID
  @HiveField(1)
  final String patientId; // The ID of the patient this alert is for
  @HiveField(2)
  final String? patientName; // Optional: Patient's name for display
  @HiveField(3)
  final String title;
  @HiveField(4)
  final String message;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  final String createdByUserId; // User who created the alert (e.g., nurse, admin)
  @HiveField(7)
  final String createdByUserName; // Name of the user who created the alert
  @HiveField(8)
  final String status; // Changed to String to handle 'pending', 'active', 'dismissed', etc.
  @HiveField(9)
  final String type; // NEW: e.g., 'emergency', 'reminder', 'info'

  Alert({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.createdByUserId,
    required this.createdByUserName,
    this.status = 'active', // Default status as string
    this.type = 'general',   // Default type as string
  });

  factory Alert.fromFirestore(Map<String, dynamic> data, String id) {
    return Alert(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'], // Can be null
      title: data['title'] ?? 'No Title',
      message: data['message'] ?? 'No Message',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdByUserId: data['createdByUserId'] ?? '',
      createdByUserName: data['createdByUserName'] ?? 'System',
      status: data['status'] ?? 'active', // Parse status as string
      type: data['type'] ?? 'general',     // Parse type as string
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'status': status, // Store status as string
      'type': type,     // Store type as string
      'createdAt': FieldValue.serverTimestamp(), // Add server timestamp on creation
    };
  }

  // Helper method to get color based on status (adapt to string status)
  static Color getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red.shade700;
      case 'dismissed':
        return Colors.grey.shade500;
      case 'critical':
        return Colors.red.shade900;
      case 'info':
        return Colors.blue.shade500;
      case 'pending': // NEW: Color for pending alerts
        return Colors.orange.shade600;
      case 'emergency': // NEW: Color for emergency type alerts (can be same as critical)
        return Colors.red.shade900;
      default:
        return Colors.grey; // Fallback color
    }
  }
}
