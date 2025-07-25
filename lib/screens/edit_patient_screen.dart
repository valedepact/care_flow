import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/screens/select_location_on_map_screen.dart'; // NEW: Import SelectLocationOnMapScreen
import 'package:google_maps_flutter/google_maps_flutter.dart'; // NEW: Import LatLng

class EditPatientScreen extends StatefulWidget {
  final Patient patient; // The patient object to be edited

  const EditPatientScreen({super.key, required this.patient});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _dateOfBirthController; // For DOB string input
  late TextEditingController _contactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _conditionController;
  late TextEditingController _medicationsController;
  late TextEditingController _treatmentHistoryController;
  late TextEditingController _notesController;
  late TextEditingController _lastVisitController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactNumberController;
  late TextEditingController _locationNameController; // NEW: For location name
  late TextEditingController _latitudeController; // NEW: For latitude
  late TextEditingController _longitudeController; // NEW: For longitude

  String? _selectedGender;
  bool _isLoading = false; // To show a loading indicator

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing patient data.
    _fullNameController = TextEditingController(text: widget.patient.name);
    _dateOfBirthController = TextEditingController(
      text: widget.patient.dob != null ? DateFormat('yyyy-MM-dd').format(widget.patient.dob!) : '',
    );
    _contactNumberController = TextEditingController(text: widget.patient.contact);
    _emailController = TextEditingController(text: widget.patient.email);
    _addressController = TextEditingController(text: widget.patient.address);
    _conditionController = TextEditingController(text: widget.patient.condition);
    _medicationsController = TextEditingController(text: widget.patient.medications.join(', '));
    _treatmentHistoryController = TextEditingController(text: widget.patient.treatmentHistory.join(', '));
    _notesController = TextEditingController(text: widget.patient.notes.join('\n'));
    _lastVisitController = TextEditingController(text: widget.patient.lastVisit);
    _emergencyContactNameController = TextEditingController(text: widget.patient.emergencyContactName ?? '');
    _emergencyContactNumberController = TextEditingController(text: widget.patient.emergencyContactNumber ?? '');
    _locationNameController = TextEditingController(text: widget.patient.locationName ?? ''); // Initialize location name
    _latitudeController = TextEditingController(text: widget.patient.latitude?.toString() ?? ''); // Initialize latitude
    _longitudeController = TextEditingController(text: widget.patient.longitude?.toString() ?? ''); // Initialize longitude

    // FIX: Ensure _selectedGender is a valid value from _genders list
    if (_genders.contains(widget.patient.gender)) {
      _selectedGender = widget.patient.gender;
    } else {
      _selectedGender = null; // Set to null if current gender is not in the list
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _conditionController.dispose();
    _medicationsController.dispose();
    _treatmentHistoryController.dispose();
    _notesController.dispose();
    _lastVisitController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _locationNameController.dispose(); // Dispose location name controller
    _latitudeController.dispose(); // Dispose latitude controller
    _longitudeController.dispose(); // Dispose longitude controller
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now().subtract(const Duration(days: 365 * 20))
          : DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  int _calculateAge(DateTime dob) {
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  // NEW: Function to navigate to map and get result
  Future<void> _selectLocationFromMap() async {
    final LatLng? initialLocation = (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty)
        ? LatLng(double.parse(_latitudeController.text), double.parse(_longitudeController.text))
        : null;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationOnMapScreen(
          initialLocation: initialLocation,
          initialLocationName: _locationNameController.text.trim(),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitudeController.text = result['latitude']?.toStringAsFixed(6) ?? '';
        _longitudeController.text = result['longitude']?.toStringAsFixed(6) ?? '';
        _locationNameController.text = result['locationName'] ?? '';
      });
    }
  }

  Future<void> _updatePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Start loading
      });

      try {
        DateTime? dob;
        int? calculatedAge; // Renamed 'age' to 'calculatedAge' for clarity with Patient model
        if (_dateOfBirthController.text.isNotEmpty) {
          dob = DateTime.parse(_dateOfBirthController.text);
          calculatedAge = _calculateAge(dob);
        }

        double? latitude = double.tryParse(_latitudeController.text.trim()); // Parse latitude
        double? longitude = double.tryParse(_longitudeController.text.trim()); // Parse longitude

        // Create a map of updated patient data
        Map<String, dynamic> updatedData = {
          'name': _fullNameController.text.trim(),
          'dob': dob != null ? Timestamp.fromDate(dob) : null, // Store DOB as Timestamp
          'calculatedAge': calculatedAge, // Store calculated age
          'gender': _selectedGender ?? 'N/A',
          'contact': _contactNumberController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'condition': _conditionController.text.trim(),
          // Split strings into lists, filter out empty strings
          'medications': _medicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'treatmentHistory': _treatmentHistoryController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'notes': _notesController.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'lastVisit': _lastVisitController.text.trim(),
          // Ensure null is saved if fields are empty, or empty string if preferred
          'emergencyContactName': _emergencyContactNameController.text.trim().isEmpty ? null : _emergencyContactNameController.text.trim(),
          'emergencyContactNumber': _emergencyContactNumberController.text.trim().isEmpty ? null : _emergencyContactNumberController.text.trim(),
          'latitude': latitude, // Include latitude in updated data
          'longitude': longitude, // Include longitude in updated data
          'locationName': _locationNameController.text.trim().isEmpty ? null : _locationNameController.text.trim(), // Include location name
          'updatedAt': FieldValue.serverTimestamp(), // Add an update timestamp
        };

        // Update the patient document in Firestore using its ID
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patient.id) // Use the existing patient's ID
            .update(updatedData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${widget.patient.name} updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to the patient profile page
      } on FirebaseException catch (e) { // Catch specific Firebase exceptions
        debugPrint('Firebase Error updating patient: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update patient: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating patient: $e'); // Use debugPrint
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.patient.name}\'s Profile'),
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
                'Patient Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectDateOfBirth(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dateOfBirthController.text.isEmpty
                        ? 'Select Date'
                        : _dateOfBirthController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text('Select Gender'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: _genders.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                  FocusScope.of(context).nextFocus();
                },
                validator: (value) => value == null ? 'Please select gender' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value) || value.length < 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient condition';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Medications (comma-separated)',
                  hintText: 'e.g., Aspirin, Ibuprofen',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _treatmentHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Treatment History (comma-separated)',
                  hintText: 'e.g., Appendectomy (2020), Flu Shot (2023)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'General Notes (each on new line)',
                  hintText: 'e.g., Patient prefers morning appointments\nAllergic to penicillin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 5,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lastVisitController,
                decoration: const InputDecoration(
                  labelText: 'Last Visit Date (YYYY-MM-DD)',
                  hintText: 'e.g., 2024-07-10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 24),

              // NEW: Location Details Section
              Text(
                'Location Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Location Name and Select from Map Button
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name (e.g., Home, Clinic)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.map, size: 30),
                    onPressed: _selectLocationFromMap, // Call the new function
                    tooltip: 'Select location on map',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.gps_fixed),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.gps_not_fixed),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emergency Contact Section
              Text(
                'Emergency Contact Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_in_talk),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _updatePatient(), // Submit form on done
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _updatePatient,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
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
