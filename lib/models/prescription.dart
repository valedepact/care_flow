import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String patientId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate; // Re-added: Medication start date
  final DateTime prescribedDate;
  final DateTime? endDate; // Optional: for prescriptions with a specific end date
  final String instructions; // Re-added: Special instructions
  final String prescribedBy; // User ID of the prescriber
  final String prescribedByName; // Re-added: Full name of the prescriber
  final DateTime createdAt; // Re-added: Timestamp of creation

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate, // Added to constructor
    required this.prescribedDate,
    this.endDate,
    required this.instructions, // Added to constructor
    required this.prescribedBy,
    required this.prescribedByName, // Added to constructor
    required this.createdAt, // Added to constructor
  });

  // Factory constructor to create a Prescription from a Firestore DocumentSnapshot
  factory Prescription.fromFirestore(Map<String, dynamic> data, String id) {
    return Prescription(
      id: id,
      patientId: data['patientId'] ?? '',
      medicationName: data['medicationName'] ?? 'Unknown Medication',
      dosage: data['dosage'] ?? 'N/A',
      frequency: data['frequency'] ?? 'N/A',
      startDate: (data['startDate'] as Timestamp).toDate(), // Parse startDate
      prescribedDate: (data['prescribedDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(), // Nullable conversion
      instructions: data['instructions'] ?? '', // Parse instructions
      prescribedBy: data['prescribedBy'] ?? '',
      prescribedByName: data['prescribedByName'] ?? 'Unknown', // Parse prescribedByName
      createdAt: (data['createdAt'] as Timestamp).toDate(), // Parse createdAt
    );
  }

  // Method to convert Prescription object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate), // Convert to Timestamp
      'prescribedDate': Timestamp.fromDate(prescribedDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null, // Convert to Timestamp
      'instructions': instructions, // Add instructions to map
      'prescribedBy': prescribedBy,
      'prescribedByName': prescribedByName, // Add prescribedByName to map
      'createdAt': FieldValue.serverTimestamp(), // Add creation timestamp
    };
  }
}
