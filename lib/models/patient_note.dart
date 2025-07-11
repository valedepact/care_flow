import 'package:cloud_firestore/cloud_firestore.dart';

class PatientNote {
  final String id;
  final String patientId;
  final String title; // e.g., "Nurse Visit Note", "Progress Update"
  final String content; // Detailed note content
  final DateTime noteDate;
  final String createdBy; // UID of the user who created the note (e.g., nurse UID)
  final String createdByName; // Name of the user who created the note

  PatientNote({
    required this.id,
    required this.patientId,
    required this.title,
    required this.content,
    required this.noteDate,
    required this.createdBy,
    required this.createdByName,
  });

  // Factory constructor to create a PatientNote from a Firestore DocumentSnapshot
  factory PatientNote.fromFirestore(Map<String, dynamic> data, String id) {
    return PatientNote(
      id: id,
      patientId: data['patientId'] ?? '',
      title: data['title'] ?? 'Untitled Note',
      content: data['content'] ?? 'No content available.',
      noteDate: (data['noteDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? 'Unknown UID',
      createdByName: data['createdByName'] ?? 'Unknown User',
    );
  }

  // Method to convert PatientNote object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'title': title,
      'content': content,
      'noteDate': noteDate,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(), // Add creation timestamp
    };
  }
}
