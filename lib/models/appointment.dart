import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For Color

// Enum for appointment status
enum AppointmentStatus {
  upcoming,
  completed,
  cancelled,
  rescheduled,
  missed,
  overdue, // NEW: Added 'overdue' status
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String type; // e.g., 'Check-up', 'Consultation', 'Vaccination'
  final DateTime dateTime;
  final String location;
  final AppointmentStatus status; // This will now represent the *current* status from Firestore
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

  // Factory constructor to create a Prescription from a Firestore DocumentSnapshot
  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    AppointmentStatus parsedStatus = AppointmentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (data['status'] ?? 'upcoming'),
      orElse: () => AppointmentStatus.upcoming,
    );

    // Determine if the appointment is overdue based on its dateTime and current time
    final DateTime appointmentDateTime = (data['dateTime'] as Timestamp).toDate();
    final bool isOverdue = appointmentDateTime.isBefore(DateTime.now()) &&
        (parsedStatus == AppointmentStatus.upcoming || parsedStatus == AppointmentStatus.rescheduled);

    // If it's overdue, override the parsed status to 'overdue'
    if (isOverdue) {
      parsedStatus = AppointmentStatus.overdue;
    }

    return Appointment(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      type: data['type'] ?? 'General Consultation',
      dateTime: appointmentDateTime, // Use the parsed DateTime
      location: data['location'] ?? 'N/A',
      status: parsedStatus, // Use the potentially overridden status
      notes: data['notes'] ?? '',
      assignedToId: data['assignedToId'],
      assignedToName: data['assignedToName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      statusColor: Appointment.getColorForStatus(parsedStatus), // Derive color based on final status
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
        return Colors.grey.shade700;
      case AppointmentStatus.overdue: // NEW: Color for overdue appointments
        return Colors.purple.shade700; // A distinct color for overdue
    }
  }

  // NEW: Getter to check if the appointment is overdue
  bool get isOverdue {
    return dateTime.isBefore(DateTime.now()) &&
        (status == AppointmentStatus.upcoming || status == AppointmentStatus.rescheduled);
  }

  // NEW: Method to get time remaining as a formatted string
  String getTimeRemainingString() {
    final Duration difference = dateTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'now';
    }
  }
}
