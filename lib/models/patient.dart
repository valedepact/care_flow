import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'patient.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String age; // Keeping as String for flexibility (e.g., "25 years", "Infant")
  @HiveField(4)
  final String gender;
  @HiveField(5)
  final String contact;
  @HiveField(6)
  final String address;
  @HiveField(7)
  final String condition;
  @HiveField(8)
  final List<String> medications;
  @HiveField(9)
  final List<String> treatmentHistory;
  @HiveField(10)
  final List<String> notes; // Keeping as List<String> for simplicity, consider a subcollection for full notes
  @HiveField(11)
  final List<String> imageUrls;
  @HiveField(12)
  final String lastVisit; // Keeping as String for simplicity, consider DateTime
  @HiveField(13)
  final String? emergencyContactName; // Nullable
  @HiveField(14)
  final String? emergencyContactNumber; // Nullable
  @HiveField(15)
  final DateTime createdAt;
  @HiveField(16)
  final String? nurseId; // Nullable, stores UID of assigned nurse
  @HiveField(17)
  final String status; // e.g., 'unassigned', 'assigned'
  @HiveField(18)
  final double? latitude; // New: Patient's location latitude
  @HiveField(19)
  final double? longitude; // New: Patient's location longitude
  @HiveField(20)
  final String? locationName; // New: A descriptive name for the patient's location
  @HiveField(21)
  final DateTime? dob; // NEW: Date of Birth as DateTime
  @HiveField(22)
  final int? calculatedAge; // NEW: Calculated age as int
  @HiveField(23)
  double? distanceFromNurse; // NEW: Added for sorting patients by distance

  Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.age, // This will be the display string
    required this.gender,
    required this.contact,
    required this.address,
    required this.condition,
    required this.medications,
    required this.treatmentHistory,
    required this.notes,
    required this.imageUrls,
    required this.lastVisit,
    this.emergencyContactName,
    this.emergencyContactNumber,
    required this.createdAt,
    this.nurseId,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationName,
    this.dob, // Include in constructor
    this.calculatedAge, // Include in constructor
    this.distanceFromNurse, // Include in constructor
  });

  // Factory constructor to create a Patient from a Firestore DocumentSnapshot
  factory Patient.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parsedDob;
    if (data['dob'] is Timestamp) {
      parsedDob = (data['dob'] as Timestamp).toDate();
    }

    int? calculatedAge;
    if (data['calculatedAge'] is num) { // Handle both int and double from Firestore
      calculatedAge = (data['calculatedAge'] as num).toInt();
    }

    // Determine the 'age' string for display
    String displayAge;
    if (calculatedAge != null) {
      displayAge = calculatedAge.toString();
    } else if (data['age'] is num) { // Fallback to old 'age' if it was a number
      displayAge = (data['age'] as num).toString();
    } else {
      displayAge = data['age'] ?? 'N/A'; // Use existing 'age' string or 'N/A'
    }

    return Patient(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      age: displayAge, // Use the derived displayAge
      gender: data['gender'] ?? 'N/A',
      contact: data['contact'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      condition: data['condition'] ?? 'N/A',
      medications: List<String>.from(data['medications'] ?? []),
      treatmentHistory: List<String>.from(data['treatmentHistory'] ?? []),
      notes: List<String>.from(data['notes'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      lastVisit: data['lastVisit'] ?? 'N/A',
      emergencyContactName: data['emergencyContactName'],
      emergencyContactNumber: data['emergencyContactNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      nurseId: data['nurseId'],
      status: data['status'] ?? 'unassigned',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationName: data['locationName'],
      dob: parsedDob, // Parse DOB
      calculatedAge: calculatedAge, // Parse calculatedAge
      // distanceFromNurse is not stored in Firestore, so it's not parsed here.
      // It will be calculated and set after fetching from Firestore.
    );
  }

  // Method to convert Patient object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'age': age, // Still store the display string age (for backward compatibility/simplicity)
      'gender': gender,
      'contact': contact,
      'address': address,
      'condition': condition,
      'medications': medications,
      'treatmentHistory': treatmentHistory,
      'notes': notes,
      'imageUrls': imageUrls,
      'lastVisit': lastVisit,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'nurseId': nurseId,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null, // Store DOB as Timestamp
      'calculatedAge': calculatedAge, // Store calculated age as int
    };
  }
}
