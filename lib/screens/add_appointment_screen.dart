import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:care_flow/models/patient.dart'; // Import Patient model

class AddAppointmentScreen extends StatefulWidget {
  final String patientId; // Can be empty if nurse is adding generally
  final String patientName; // Can be empty if nurse is adding generally

  const AddAppointmentScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Changed _typeController to _selectedType for Dropdown
  String? _selectedType;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _patientNameDisplayController = TextEditingController();

  User? _currentUser;
  String? _currentUserName;
  bool _isLoading = false;
  bool _isInitialTimeSet = false;

  // List of predefined appointment types
  final List<String> _appointmentTypes = [
    'Home Visit',
    'Clinic Appointment',
    'Teleconsultation',
    'Follow-up',
    'Emergency Visit',
    'Routine Check-up',
    'Vaccination',
  ];

  // State for patient selection
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<Patient> _assignedPatients = [];
  bool _isPatientSelectionLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    // Set initial date to current date
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // If patientId is provided (from PatientProfilePage), pre-fill and set selected patient
    if (widget.patientId.isNotEmpty) {
      _selectedPatientId = widget.patientId;
      _selectedPatientName = widget.patientName;
      _patientNameDisplayController.text = widget.patientName;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize time here where context is fully available
    if (!_isInitialTimeSet) {
      _timeController.text = TimeOfDay.now().format(context);
      _isInitialTimeSet = true;
    }
  }

  @override
  void dispose() {
    // _typeController.dispose(); // No longer needed for Dropdown
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _patientNameDisplayController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentUser() async {
    final currentContext = context;

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('User not logged in. Cannot add appointment.'), backgroundColor: Colors.red),
        );
        Navigator.pop(currentContext);
      }
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (!currentContext.mounted) return;

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Unknown Nurse';
        // If coming from general "Add Appointment" (patientId is empty), fetch assigned patients
        if (widget.patientId.isEmpty) {
          await _fetchAssignedPatients();
        }
      } else {
        _currentUserName = 'Unknown Nurse';
      }
    } catch (e) {
      debugPrint('Error fetching current user name for appointment: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Fetch assigned patients for the current nurse
  Future<void> _fetchAssignedPatients() async {
    final currentContext = context;
    setState(() {
      _isPatientSelectionLoading = true;
      _assignedPatients.clear();
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: _currentUser!.uid)
          .orderBy('name')
          .get();

      if (!currentContext.mounted) return;

      setState(() {
        _assignedPatients = snapshot.docs.map((doc) {
          return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        _isPatientSelectionLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching assigned patients: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to load assigned patients: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isPatientSelectionLoading = false;
      });
    }
  }

  // Dialog to select a patient
  void _showPatientSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Patient'),
          content: _isPatientSelectionLoading
              ? const Center(child: CircularProgressIndicator())
              : _assignedPatients.isEmpty
              ? const Text('No patients assigned to you.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _assignedPatients.length,
              itemBuilder: (context, index) {
                final patient = _assignedPatients[index];
                return ListTile(
                  title: Text(patient.name),
                  subtitle: Text('ID: ${patient.id}'),
                  onTap: () {
                    setState(() {
                      _selectedPatientId = patient.id;
                      _selectedPatientName = patient.name;
                      _patientNameDisplayController.text = patient.name;
                    });
                    Navigator.pop(dialogContext); // Close dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 years back
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years forward
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _addAppointment() async {
    final currentContext = context;

    if (_formKey.currentState!.validate()) {
      if (_currentUser == null || _currentUserName == null) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('User not authenticated. Cannot add appointment.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Validate if a patient has been selected
      if (_selectedPatientId == null || _selectedPatientName == null || _selectedPatientId!.isEmpty) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Please select a patient for the appointment.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Validate if an appointment type has been selected
      if (_selectedType == null || _selectedType!.isEmpty) {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Please select an appointment type.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Combine date and time
        DateTime date = DateTime.parse(_dateController.text);
        TimeOfDay time;
        try {
          // Attempt to parse the time. If it fails, default to TimeOfDay.now()
          DateTime? parsedTime = DateFormat('h:mm a').parse(_timeController.text);
          time = TimeOfDay.fromDateTime(parsedTime);
                } catch (e) {
          debugPrint('Error parsing time string "${_timeController.text}": $e. Defaulting to current time.');
          time = TimeOfDay.now();
        }


        DateTime appointmentDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final Appointment newAppointment = Appointment(
          id: '', // Firestore will generate this
          patientId: _selectedPatientId!, // Use selected patient ID
          patientName: _selectedPatientName!, // Use selected patient Name
          type: _selectedType!, // Use the selected appointment type
          dateTime: appointmentDateTime,
          location: _locationController.text.trim(),
          status: AppointmentStatus.upcoming, // Default to upcoming
          notes: _notesController.text.trim(),
          assignedToId: _currentUser!.uid,
          assignedToName: _currentUserName!,
          createdAt: DateTime.now(), // Will be overwritten by serverTimestamp in toFirestore
        );

        await FirebaseFirestore.instance.collection('appointments').add(newAppointment.toFirestore());

        if (!currentContext.mounted) return;

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Appointment added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(currentContext); // Go back to patient profile
      } on FirebaseException catch (e) {
        debugPrint('Firebase Error adding appointment: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add appointment: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint('Error adding appointment: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add appointment: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Appointment ${widget.patientId.isNotEmpty ? "for ${widget.patientName}" : ""}'), // Dynamic title
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
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
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Patient Selection Field (only if patientId is not pre-filled)
              if (widget.patientId.isEmpty) ...[
                InkWell(
                  onTap: _showPatientSelectionDialog,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Patient',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_search),
                      // Validator for patient selection
                      errorText: (_selectedPatientId == null || _selectedPatientId!.isEmpty) && _formKey.currentState?.validate() == false
                          ? 'Please select a patient'
                          : null,
                    ),
                    child: Text(
                      _patientNameDisplayController.text.isEmpty
                          ? 'Tap to select patient'
                          : _patientNameDisplayController.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Display patient name if pre-filled (from PatientProfilePage)
              if (widget.patientId.isNotEmpty) ...[
                TextFormField(
                  controller: _patientNameDisplayController,
                  readOnly: true, // Make it read-only as it's pre-filled
                  decoration: const InputDecoration(
                    labelText: 'Patient',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Appointment Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: const Text('Select Appointment Type'),
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
                    _selectedType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an appointment type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dateController.text.isEmpty
                        ? 'Select Date'
                        : _dateController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time Picker
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _timeController.text.isEmpty
                        ? 'Select Time'
                        : _timeController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., Clinic Address, Online)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g., Patient prefers morning, bring previous reports',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _addAppointment,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Schedule Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
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
