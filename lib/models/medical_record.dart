import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String title; // e.g., "Blood Test Results", "X-Ray Report"
  final String type; // e.g., "Lab Result", "Imaging", "Consultation Note"
  final DateTime recordDate;
  final String content; // Detailed notes or summary of the record
  final String? doctorName; // Doctor who created/reviewed the record
  final String? fileUrl; // Optional: URL to a file (e.g., PDF, image)

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.title,
    required this.type,
    required this.recordDate,
    required this.content,
    this.doctorName,
    this.fileUrl,
  });

  // Factory constructor to create a MedicalRecord from a Firestore DocumentSnapshot
  factory MedicalRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return MedicalRecord(
      id: id,
      patientId: data['patientId'] ?? '',
      title: data['title'] ?? 'Untitled Record',
      type: data['type'] ?? 'General',
      recordDate: (data['recordDate'] as Timestamp).toDate(),
      content: data['content'] ?? 'No content available.',
      doctorName: data['doctorName'],
      fileUrl: data['fileUrl'],
    );
  }

  // Method to convert MedicalRecord object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'title': title,
      'type': type,
      'recordDate': recordDate,
      'content': content,
      'doctorName': doctorName,
      'fileUrl': fileUrl,
      'createdAt': FieldValue.serverTimestamp(), // Add creation timestamp
    };
  }
}
