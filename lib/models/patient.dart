import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String name;
  final int age; // Changed to int
  final DateTime? dob; // Added Date of Birth as DateTime
  final String gender;
  final String contact;
  final String address;
  final String condition;
  final List<dynamic> medications; // Use dynamic for lists from Firestore
  final List<dynamic> treatmentHistory; // Use dynamic for lists from Firestore
  final String lastVisit;
  final String? email; // Nullable
  final String? emergencyContactName; // Nullable
  final String? emergencyContactNumber; // Nullable
  final String? nurseId; // ID of the assigned nurse
  final String status; // e.g., 'unassigned', 'assigned'
  final List<dynamic> notes; // For patient-specific notes
  final List<dynamic> imageUrls; // For storing image URLs

  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.dob, // dob is now optional in constructor
    required this.gender,
    required this.contact,
    required this.address,
    required this.condition,
    required this.medications,
    required this.treatmentHistory,
    required this.lastVisit,
    this.email,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.nurseId,
    this.status = 'unassigned', // Default status
    this.notes = const [],
    this.imageUrls = const [],
  });

  factory Patient.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parsedDob;
    if (data['dob'] is Timestamp) {
      parsedDob = (data['dob'] as Timestamp).toDate();
    }

    // Calculate age from DOB, or use a default if DOB is missing
    int calculatedAge = 0;
    if (parsedDob != null) {
      DateTime today = DateTime.now();
      calculatedAge = today.year - parsedDob.year;
      if (today.month < parsedDob.month ||
          (today.month == parsedDob.month && today.day < parsedDob.day)) {
        calculatedAge--;
      }
    } else {
      // Fallback if dob is not available or invalid
      calculatedAge = int.tryParse(data['age']?.toString() ?? '0') ?? 0;
    }


    return Patient(
      id: id,
      name: data['name'] ?? 'Unknown Patient',
      age: calculatedAge, // Use calculated age
      dob: parsedDob, // Store parsed DOB
      gender: data['gender'] ?? 'N/A',
      contact: data['contact'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      condition: data['condition'] ?? 'N/A',
      medications: List<dynamic>.from(data['medications'] ?? []),
      treatmentHistory: List<dynamic>.from(data['treatmentHistory'] ?? []),
      lastVisit: data['lastVisit'] ?? 'N/A',
      email: data['email'],
      emergencyContactName: data['emergencyContactName'],
      emergencyContactNumber: data['emergencyContactNumber'],
      nurseId: data['nurseId'],
      status: data['status'] ?? 'unassigned',
      notes: List<dynamic>.from(data['notes'] ?? []),
      imageUrls: List<dynamic>.from(data['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age, // Store calculated age
      'dob': dob != null ? Timestamp.fromDate(dob!) : null, // Store DOB as Timestamp
      'gender': gender,
      'contact': contact,
      'address': address,
      'condition': condition,
      'medications': medications,
      'treatmentHistory': treatmentHistory,
      'lastVisit': lastVisit,
      'email': email,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'nurseId': nurseId,
      'status': status,
      'notes': notes,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(), // Add creation timestamp if not already present
    };
  }
}
