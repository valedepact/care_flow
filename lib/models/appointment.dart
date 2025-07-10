// models/appointment.dart
import 'package:flutter/material.dart'; // For Color

enum AppointmentStatus { missed, completed, upcoming }

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String location;
  final AppointmentStatus status;
  final String notes;
  final Color statusColor; // For color-coded time blocks

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.location,
    this.status = AppointmentStatus.upcoming,
    this.notes = '',
    required this.statusColor, // Ensure this is passed
  });

  // Helper to get color based on status
  static Color getColorForStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.missed:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.upcoming:
      default:
        return Colors.blue;
    }
  }

  // Factory constructor for creating an Appointment from a map
  factory Appointment.fromMap(Map<String, dynamic> data, String id) {
    final statusString = data['status'] as String;
    AppointmentStatus parsedStatus;
    switch (statusString) {
      case 'missed':
        parsedStatus = AppointmentStatus.missed;
        break;
      case 'completed':
        parsedStatus = AppointmentStatus.completed;
        break;
      case 'upcoming':
      default:
        parsedStatus = AppointmentStatus.upcoming;
        break;
    }

    return Appointment(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      dateTime: DateTime.parse(data['dateTime']),
      location: data['location'] ?? '',
      status: parsedStatus,
      notes: data['notes'] ?? '',
      statusColor: Appointment.getColorForStatus(parsedStatus), // Set color based on parsed status
    );
  }

  // Method to convert Appointment to a map
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'status': status.toString().split('.').last, // Convert enum to string
      'notes': notes,
    };
  }
}
