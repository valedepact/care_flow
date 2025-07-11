import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedPatientId; // Store patient ID
  String? _selectedPatientName; // Store patient name for display
  String? _selectedDoctorId; // Store doctor/nurse ID
  String? _selectedDoctorName; // Store doctor/nurse name for display

  String _appointmentType = 'Consultation';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoadingPatients = true;
  bool _isLoadingDoctors = true;
  bool _isSavingAppointment = false;

  List<Map<String, String>> _patients = []; // List of {'id': '...', 'name': '...'}
  List<Map<String, String>> _doctorsAndNurses = []; // List of {'id': '...', 'name': '...'}

  final List<String> _appointmentTypes = ['Consultation', 'Follow-up', 'Procedure', 'Vaccination'];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _fetchDoctorsAndNurses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoadingPatients = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('patients').get();
      List<Map<String, String>> fetchedPatients = snapshot.docs.map((doc) {
        // Explicitly cast values to String to match List<Map<String, String>>
        return {'id': doc.id, 'name': (doc['name'] ?? 'Unknown Patient') as String};
      }).toList();

      if (mounted) {
        setState(() {
          _patients = fetchedPatients;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      print('Error fetching patients for dropdown: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoadingPatients = false;
        });
      }
    }
  }

  Future<void> _fetchDoctorsAndNurses() async {
    setState(() {
      _isLoadingDoctors = true;
    });
    try {
      // Fetch users with role 'Nurse'
      QuerySnapshot nurseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Nurse')
          .get();

      List<Map<String, String>> fetchedPersonnel = nurseSnapshot.docs.map((doc) {
        // Explicitly cast values to String to match List<Map<String, String>>
        return {'id': doc.id, 'name': (doc['fullName'] ?? 'Unknown Nurse') as String};
      }).toList();

      // If you had a 'Doctor' role, you'd fetch them similarly and add to the list
      // QuerySnapshot doctorSnapshot = await FirebaseFirestore.instance
      //     .collection('users')
      //     .where('role', isEqualTo: 'Doctor')
      //     .get();
      // fetchedPersonnel.addAll(doctorSnapshot.docs.map((doc) {
      //   return {'id': doc.id, 'name': doc['fullName'] ?? 'Unknown Doctor'};
      // }).toList());

      if (mounted) {
        setState(() {
          _doctorsAndNurses = fetchedPersonnel;
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      print('Error fetching doctors/nurses for dropdown: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading care personnel: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoadingDoctors = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatientId == null || _selectedDoctorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both a patient and a care personnel.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSavingAppointment = true; // Start loading
      });

      try {
        // Combine date and time into a single DateTime object
        final DateTime appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Prepare appointment data for Firestore
        Map<String, dynamic> appointmentData = {
          'patientId': _selectedPatientId,
          'patientName': _selectedPatientName,
          'assignedToId': _selectedDoctorId, // Can be nurse or doctor
          'assignedToName': _selectedDoctorName,
          'type': _appointmentType,
          'dateTime': appointmentDateTime, // Firestore will convert this to Timestamp
          'notes': _notesController.text.trim(),
          'status': 'upcoming', // Default status
          'location': 'Clinic Visit', // Placeholder, can be made dynamic later
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add the appointment data to the 'appointments' collection
        await FirebaseFirestore.instance.collection('appointments').add(appointmentData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment for $_selectedPatientName scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Optionally clear fields after adding
          _notesController.clear();
          setState(() {
            _selectedPatientId = null;
            _selectedPatientName = null;
            _selectedDoctorId = null;
            _selectedDoctorName = null;
            _appointmentType = 'Consultation';
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
          });
          // Optionally pop the screen to go back to the previous one (e.g., Nurse Dashboard)
          // Navigator.pop(context);
        }
      } catch (e) {
        print('Error adding appointment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSavingAppointment = false; // Stop loading
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Appointment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointment Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Patient Selection
              _isLoadingPatients
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedPatientId,
                hint: const Text('Select Patient'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _patients.map((Map<String, String> patient) {
                  return DropdownMenuItem<String>(
                    value: patient['id'],
                    child: Text(patient['name']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPatientId = newValue;
                    // Find the patient name from the fetched list
                    _selectedPatientName = _patients.firstWhere((p) => p['id'] == newValue)['name'];
                  });
                },
                validator: (value) => value == null ? 'Please select a patient' : null,
              ),
              const SizedBox(height: 16),

              // Doctor/Nurse Selection
              _isLoadingDoctors
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedDoctorId,
                hint: const Text('Select Care Personnel'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                items: _doctorsAndNurses.map((Map<String, String> personnel) {
                  return DropdownMenuItem<String>(
                    value: personnel['id'],
                    child: Text(personnel['name']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDoctorId = newValue;
                    // Find the personnel name from the fetched list
                    _selectedDoctorName = _doctorsAndNurses.firstWhere((p) => p['id'] == newValue)['name'];
                  });
                },
                validator: (value) => value == null ? 'Please select care personnel' : null,
              ),
              const SizedBox(height: 16),

              // Appointment Type Selection
              DropdownButtonFormField<String>(
                value: _appointmentType,
                decoration: const InputDecoration(
                  labelText: 'Appointment Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _appointmentTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _appointmentType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Date and Time Pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes for the appointment
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Appointment Notes (Optional)',
                  hintText: 'e.g., "Patient prefers morning appointments"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              // Add Appointment Button
              SizedBox(
                width: double.infinity,
                child: _isSavingAppointment
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _addAppointment,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
