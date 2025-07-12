import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Color

// Enum for appointment status
enum AppointmentStatus {
  upcoming,
  completed,
  cancelled,
  rescheduled,
  missed, // Added 'missed' status
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String type; // e.g., 'Check-up', 'Consultation', 'Vaccination'
  final DateTime dateTime;
  final String location;
  final AppointmentStatus status;
  final String notes;
  final String? assignedToId; // ID of the nurse/caregiver assigned
  final String? assignedToName; // Name of the nurse/caregiver assigned
  final DateTime createdAt;
  final Color statusColor; // Derived color for UI

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.dateTime,
    required this.location,
    required this.status,
    this.notes = '',
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
    required this.statusColor, // Must be provided during construction
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    AppointmentStatus parsedStatus = AppointmentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
      orElse: () => AppointmentStatus.upcoming,
    );

    return Appointment(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      type: data['type'] ?? 'General Consultation',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] ?? 'N/A',
      status: parsedStatus,
      notes: data['notes'] ?? '',
      assignedToId: data['assignedToId'],
      assignedToName: data['assignedToName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      statusColor: Appointment.getColorForStatus(parsedStatus), // Derive color here
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'type': type,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'status': status.toString().split('.').last, // Store enum as string
      'notes': notes,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper method to get color based on status (used in fromFirestore as well)
  static Color getColorForStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Colors.blue.shade600;
      case AppointmentStatus.completed:
        return Colors.green.shade600;
      case AppointmentStatus.cancelled:
        return Colors.red.shade600;
      case AppointmentStatus.rescheduled:
        return Colors.orange.shade600;
      case AppointmentStatus.missed:
        return Colors.grey.shade700; // Corrected: Using a valid shade of grey
    }
  }
}
