import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String patientId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime prescribedDate;
  final DateTime? endDate; // Optional: for prescriptions with a specific end date
  final String prescribedBy; // Doctor or Nurse who prescribed it
  final String notes; // Any special instructions

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.prescribedDate,
    this.endDate,
    required this.prescribedBy,
    this.notes = '',
  });

  // Factory constructor to create a Prescription from a Firestore DocumentSnapshot
  factory Prescription.fromFirestore(Map<String, dynamic> data, String id) {
    return Prescription(
      id: id,
      patientId: data['patientId'] ?? '',
      medicationName: data['medicationName'] ?? 'Unknown Medication',
      dosage: data['dosage'] ?? 'N/A',
      frequency: data['frequency'] ?? 'N/A',
      prescribedDate: (data['prescribedDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(), // Nullable conversion
      prescribedBy: data['prescribedBy'] ?? 'Unknown',
      notes: data['notes'] ?? '',
    );
  }

  // Method to convert Prescription object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'prescribedDate': prescribedDate,
      'endDate': endDate,
      'prescribedBy': prescribedBy,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(), // Add creation timestamp
    };
  }
}
