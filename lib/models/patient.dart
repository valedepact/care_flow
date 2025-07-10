

class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String address;
  final String condition;
  final List<String> medications;
  final List<String> treatmentHistory;
  final List<String> notes; // For nurse updates
  final List<String> imageUrls; // For images of wounds or medical reports
  final String lastVisit;
  final String nextAppointmentId; // Link to an appointment if any

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.contact = 'N/A',
    this.address = 'N/A',
    required this.condition,
    this.medications = const [],
    this.treatmentHistory = const [],
    this.notes = const [],
    this.imageUrls = const [],
    required this.lastVisit,
    this.nextAppointmentId = '',
  });

  // Factory constructor for creating a Patient from a map (e.g., from Firebase)
  factory Patient.fromMap(Map<String, dynamic> data, String id) {
    return Patient(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 'N/A',
      gender: data['gender'] ?? 'N/A',
      contact: data['contact'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      condition: data['condition'] ?? '',
      medications: List<String>.from(data['medications'] ?? []),
      treatmentHistory: List<String>.from(data['treatmentHistory'] ?? []),
      notes: List<String>.from(data['notes'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      lastVisit: data['lastVisit'] ?? '',
      nextAppointmentId: data['nextAppointmentId'] ?? '',
    );
  }

  // Method to convert Patient to a map (e.g., for Firebase)
  Map<String, dynamic> toMap() {
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
    };
  }
}
