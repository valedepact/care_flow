import 'package:flutter/material.dart'; // For Color in AppointmentStatus

// Re-defining the AppointmentStatus and Appointment classes here
// to ensure they are available for the Patient model if needed,
// and to keep related models together or clearly defined.
enum AppointmentStatus {
  upcoming,
  completed,
  missed,
  cancelled,
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String location;
  final AppointmentStatus status;
  final String notes;
  final Color statusColor; // Added for UI representation

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.location,
    required this.status,
    this.notes = '',
    required this.statusColor,
  });

  // Helper to get color based on status
  static Color getColorForStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Colors.blue.shade400;
      case AppointmentStatus.completed:
        return Colors.green.shade400;
      case AppointmentStatus.missed:
        return Colors.red.shade400;
      case AppointmentStatus.cancelled:
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }
}

// Patient Model: Updated to include emergency contact information
class Patient {
  final String id;
  final String name;
  final String age; // Can be '20' or '1990-01-01' (date string)
  final String gender;
  final String contact;
  final String address;
  final String condition;
  final List<String> medications;
  final List<String> treatmentHistory;
  final List<String> notes; // For nurse's progress notes etc.
  final List<String> imageUrls; // Placeholder for patient photos/documents
  final String lastVisit;
  final String? nextAppointmentId; // Optional, links to an appointment

  // New fields for emergency contact
  final String? emergencyContactName;
  final String? emergencyContactNumber;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.condition,
    this.medications = const [],
    this.treatmentHistory = const [],
    this.notes = const [],
    this.imageUrls = const [],
    this.lastVisit = 'N/A',
    this.nextAppointmentId,
    this.emergencyContactName, // New
    this.emergencyContactNumber, // New
  });

  // Factory constructor to create a Patient from a Firestore DocumentSnapshot
  factory Patient.fromFirestore(Map<String, dynamic> data, String id) {
    return Patient(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      contact: data['contact'] ?? '',
      address: data['address'] ?? '',
      condition: data['condition'] ?? '',
      medications: List<String>.from(data['medications'] ?? []),
      treatmentHistory: List<String>.from(data['treatmentHistory'] ?? []),
      notes: List<String>.from(data['notes'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      lastVisit: data['lastVisit'] ?? 'N/A',
      nextAppointmentId: data['nextAppointmentId'],
      emergencyContactName: data['emergencyContactName'], // New
      emergencyContactNumber: data['emergencyContactNumber'], // New
    );
  }

  // Method to convert Patient object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'address': address,
      'condition': condition,
      'medications': medications,
      'treatmentHistory': treatmentHistory,
      'notes': notes,
      'imageUrls': imageUrls,
      'lastVisit': lastVisit,
      'nextAppointmentId': nextAppointmentId,
      'emergencyContactName': emergencyContactName, // New
      'emergencyContactNumber': emergencyContactNumber, // New
    };
  }
}
