

class Nurse {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String contact;
  final String address;
  final String certification;
  final List<String> patients;
  final List<String> treatmentHistory;
  final String nextAppointmentId; // Link to an appointment if any

  Nurse({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.contact = 'N/A',
    this.address = 'N/A',
    required this.certification,
    this.treatmentHistory = const [],
    this.patients = const [],
    this.nextAppointmentId = '',
  });

  // Factory constructor for creating a Patient from a map (e.g., from Firebase)
  factory Nurse.fromMap(Map<String, dynamic> data, String id) {
    return Nurse(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 'N/A',
      gender: data['gender'] ?? 'N/A',
      contact: data['contact'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      patients: List<String>.from(data['patients'] ?? []),
      treatmentHistory: List<String>.from(data['treatmentHistory'] ?? []),
      nextAppointmentId: data['nextAppointmentId'] ?? '', certification: '',
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
      'certification': certification,
      'patients': patients,
      'treatmentHistory': treatmentHistory,
      'nextAppointmentId': nextAppointmentId,
    };
  }
}
