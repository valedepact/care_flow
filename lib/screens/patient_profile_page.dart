import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user
import 'package:intl/intl.dart'; // For DateFormat
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:care_flow/screens/patient_notes_screen.dart'; // Import PatientNotesScreen
import 'package:care_flow/screens/medical_records_page.dart'; // Import MedicalRecordsPage
import 'package:care_flow/screens/patient_prescriptions_screen.dart'; // Import PatientPrescriptionsScreen
import 'package:care_flow/screens/add_appointment_screen.dart'; // Import AddAppointmentScreen
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'package:care_flow/screens/select_location_on_map_screen.dart'; // NEW: Import the map selection screen
import 'package:care_flow/screens/edit_patient_screen.dart'; // Explicitly import EditPatientScreen
import 'package:hive/hive.dart';

class PatientProfilePage extends StatefulWidget {
  final String? patientId; // Now optional
  final String? patientName; // Now optional

  const PatientProfilePage({
    super.key,
    this.patientId, // Make optional
    this.patientName, // Make optional
  });

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  Patient? _patient;
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentUser;
  String? _currentUserRole; // To determine if current user is Patient or Nurse

  bool _isEditing = false; // State to toggle inline edit mode for patient self-edit

  // Declare _formKey for the Form widget
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactNumberController;
  late TextEditingController _dobController;
  late TextEditingController _locationNameController;
  late TextEditingController _latitudeController; // Still needed to store/display
  late TextEditingController _longitudeController; // Still needed to store/display


  @override
  void initState() {
    super.initState();
    debugPrint('PatientProfilePage: initState called.');
    _contactController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyContactNameController = TextEditingController();
    _emergencyContactNumberController = TextEditingController();
    _dobController = TextEditingController();
    _locationNameController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _initializeUserDataAndFetchPatient(); // Combined initialization
  }

  @override
  void dispose() {
    _contactController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _dobController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserDataAndFetchPatient() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in. Cannot fetch profile.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserRole = userDoc.get('role');
      } else {
        _currentUserRole = 'Unknown';
      }

      await _fetchPatientDetails();
    } catch (e) {
      debugPrint('PatientProfilePage: Error initializing user data: $e');
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientDetails() async {
    final currentContext = context;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    debugPrint('PatientProfilePage: _fetchPatientDetails - Current User UID: ${_currentUser?.uid}');

    String? targetPatientId;
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      targetPatientId = widget.patientId;
      debugPrint('PatientProfilePage: _fetchPatientDetails - Using widget.patientId: $targetPatientId');
    } else {
      if (_currentUser == null) {
        if (currentContext.mounted) {
          setState(() {
            _errorMessage = 'User not logged in. Cannot fetch profile.';
            _isLoading = false;
          });
        }
        debugPrint('PatientProfilePage: _fetchPatientDetails - User not logged in, setting error.');
        return;
      }
      targetPatientId = _currentUser!.uid;
      debugPrint('PatientProfilePage: _fetchPatientDetails - Using current user UID: $targetPatientId');
    }

    if (targetPatientId == null) {
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'No patient ID available.';
          _isLoading = false;
        });
      }
      debugPrint('PatientProfilePage: _fetchPatientDetails - No targetPatientId, setting error.');
      return;
    }

    // 1. Try to load from Hive first
    var patientBox = Hive.box<Patient>('patients');
    Patient? localPatient;
    try {
      localPatient = patientBox.values.firstWhere((p) => p.id == targetPatientId);
    } catch (_) {
      localPatient = null;
    }
    if (localPatient != null) {
      setState(() {
        _patient = localPatient;
        _contactController.text = _patient!.contact;
        _addressController.text = _patient!.address;
        _emergencyContactNameController.text = _patient!.emergencyContactName ?? '';
        _emergencyContactNumberController.text = _patient!.emergencyContactNumber ?? '';
        if (_patient!.dob != null) {
          _dobController.text = DateFormat('yyyy-MM-dd').format(_patient!.dob!);
        } else {
          _dobController.clear();
        }
        _locationNameController.text = _patient!.locationName ?? '';
        _latitudeController.text = _patient!.latitude?.toString() ?? '';
        _longitudeController.text = _patient!.longitude?.toString() ?? '';
        _isLoading = false;
      });
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(targetPatientId)
          .get();

      if (!currentContext.mounted) {
        debugPrint('PatientProfilePage: _fetchPatientDetails - Widget unmounted after Firestore fetch.');
        return;
      }

      if (doc.exists) {
        setState(() {
          _patient = Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          // Initialize controllers with fetched data
          _contactController.text = _patient!.contact;
          _addressController.text = _patient!.address;
          _emergencyContactNameController.text = _patient!.emergencyContactName ?? '';
          _emergencyContactNumberController.text = _patient!.emergencyContactNumber ?? '';
          if (_patient!.dob != null) {
            _dobController.text = DateFormat('yyyy-MM-dd').format(_patient!.dob!);
          } else {
            _dobController.clear();
          }
          _locationNameController.text = _patient!.locationName ?? '';
          _latitudeController.text = _patient!.latitude?.toString() ?? '';
          _longitudeController.text = _patient!.longitude?.toString() ?? '';
          _isLoading = false;
        });
        // Update Hive with the latest patient data
        int localIndex = patientBox.values.toList().indexWhere((p) => p.id == doc.id);
        if (localIndex != -1) {
          await patientBox.putAt(localIndex, _patient!);
        } else {
          await patientBox.add(_patient!);
        }
        debugPrint('PatientProfilePage: _fetchPatientDetails - Patient data loaded successfully for ID: ${_patient!.id}');
      } else {
        setState(() {
          _errorMessage = 'Patient not found.';
          _isLoading = false;
        });
        debugPrint('PatientProfilePage: _fetchPatientDetails - Patient document not found for ID: $targetPatientId');
      }
    } catch (e) {
      debugPrint('PatientProfilePage: _fetchPatientDetails - Error fetching patient details: $e');
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'Error loading patient details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text) ?? DateTime.now().subtract(const Duration(days: 365 * 20))
          : DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      debugPrint('PatientProfilePage: Date of birth selected: ${_dobController.text}');
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

  Future<void> _updateProfile() async {
    final currentContext = context;
    if (_patient == null || _currentUser == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error: Patient data or user not loaded.'), backgroundColor: Colors.red),
        );
      }
      debugPrint('PatientProfilePage: _updateProfile - Patient data or current user is null. Aborting update.');
      return;
    }

    debugPrint('PatientProfilePage: _updateProfile - Current User UID: ${_currentUser!.uid}, Patient ID: ${_patient!.id}');
    // This check is for patient self-edit. Nurse editing is handled via EditPatientScreen.
    if (_currentUser!.uid != _patient!.id) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('You do not have permission to edit this profile directly.'), backgroundColor: Colors.red),
        );
      }
      debugPrint('PatientProfilePage: _updateProfile - Permission denied: Current user is not the patient. Nurse should use dedicated EditPatientScreen.');
      return;
    }

    if (_formKey.currentState!.validate()) { // Use the declared _formKey here
      setState(() {
        _isLoading = true;
      });
      debugPrint('PatientProfilePage: _updateProfile - Form is valid, starting update...');

      try {
        DateTime? dob;
        int? calculatedAge;
        if (_dobController.text.isNotEmpty) {
          try {
            dob = DateFormat('yyyy-MM-dd').parse(_dobController.text);
            calculatedAge = _calculateAge(dob);
            debugPrint('PatientProfilePage: _updateProfile - Parsed DOB: $dob, Calculated Age: $calculatedAge');
          } catch (e) {
            debugPrint('PatientProfilePage: Error parsing DOB in _updateProfile: $e');
            dob = null;
            calculatedAge = null;
          }
        }

        double? latitude = double.tryParse(_latitudeController.text.trim());
        double? longitude = double.tryParse(_longitudeController.text.trim());
        debugPrint('PatientProfilePage: _updateProfile - Parsed Latitude: $latitude, Longitude: $longitude');


        Map<String, dynamic> updatedData = {
          'contact': _contactController.text.trim(),
          'address': _addressController.text.trim(),
          'emergencyContactName': _emergencyContactNameController.text.trim().isNotEmpty
              ? _emergencyContactNameController.text.trim()
              : null,
          'emergencyContactNumber': _emergencyContactNumberController.text.trim().isNotEmpty
              ? _emergencyContactNumberController.text.trim()
              : null,
          'dob': dob,
          'calculatedAge': calculatedAge,
          'locationName': _locationNameController.text.trim().isNotEmpty
              ? _locationNameController.text.trim()
              : null,
          'latitude': latitude,
          'longitude': longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        debugPrint('PatientProfilePage: _updateProfile - Data to be updated: $updatedData');


        await FirebaseFirestore.instance
            .collection('patients')
            .doc(_patient!.id)
            .update(updatedData);

        if (!currentContext.mounted) {
          debugPrint('PatientProfilePage: _updateProfile - Widget unmounted after Firestore update.');
          return;
        }

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditing = false; // Exit edit mode on successful save
        });
        debugPrint('PatientProfilePage: _updateProfile - Profile updated successfully, exiting edit mode.');
        _fetchPatientDetails(); // Re-fetch to update displayed data
      } on FirebaseException catch (e) {
        debugPrint('PatientProfilePage: Firebase Error updating profile: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint('PatientProfilePage: Error updating profile: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          debugPrint('PatientProfilePage: _updateProfile - Loading state set to false.');
        }
      }
    } else {
      debugPrint('PatientProfilePage: _updateProfile - Form validation failed.');
    }
  }

  // Determine if the current user is the patient whose profile is being viewed/edited
  bool get _isCurrentUserPatient {
    final bool result = _currentUser != null && _patient != null && _currentUser!.uid == _patient!.id;
    debugPrint('PatientProfilePage: _isCurrentUserPatient check: Current User UID: ${_currentUser?.uid}, Patient ID: ${_patient?.id}, Result: $result');
    return result;
  }

  // Determine if the current user is the nurse assigned to this patient
  bool get _isAssignedNurse {
    final bool result = _currentUserRole == 'Nurse' && _patient != null && _patient!.nurseId == _currentUser!.uid;
    debugPrint('PatientProfilePage: _isAssignedNurse check: Current User Role: $_currentUserRole, Patient Nurse ID: ${_patient?.nurseId}, Current User UID: ${_currentUser?.uid}, Result: $result');
    return result;
  }

  // NEW: Function to navigate to map selection screen
  Future<void> _selectLocationOnMap() async {
    final currentContext = context;
    LatLng? initialLatLng;
    if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
      initialLatLng = LatLng(double.parse(_latitudeController.text), double.parse(_longitudeController.text));
    }

    final result = await Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (context) => SelectLocationOnMapScreen(
          initialLocation: initialLatLng,
          initialLocationName: _locationNameController.text,
        ),
      ),
    );

    if (!currentContext.mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitudeController.text = result['latitude']?.toString() ?? '';
        _longitudeController.text = result['longitude']?.toString() ?? '';
        _locationNameController.text = result['locationName'] ?? '';
      });
      debugPrint('PatientProfilePage: Location selected from map: Lat: ${_latitudeController.text}, Lng: ${_longitudeController.text}, Name: ${_locationNameController.text}');
    }
  }


  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.patientName != null && widget.patientName!.isNotEmpty
        ? '${widget.patientName!}\'s Profile'
        : (_patient?.name != null && _patient!.name.isNotEmpty ? '${_patient!.name}\'s Profile' : 'Patient Profile');

    debugPrint('PatientProfilePage: build method - _isEditing: $_isEditing, _isCurrentUserPatient: $_isCurrentUserPatient, _isAssignedNurse: $_isAssignedNurse');

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Show edit button only if current user is the patient themselves
          if (_isCurrentUserPatient)
            IconButton(
              icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  debugPrint('PatientProfilePage: Edit button pressed. _isEditing toggled to: $_isEditing');
                  if (!_isEditing) {
                    // If exiting edit mode without saving, reset controllers to original data
                    debugPrint('PatientProfilePage: Exiting edit mode, resetting controllers.');
                    _contactController.text = _patient!.contact;
                    _addressController.text = _patient!.address;
                    _emergencyContactNameController.text = _patient!.emergencyContactName ?? '';
                    _emergencyContactNumberController.text = _patient!.emergencyContactNumber ?? '';
                    if (_patient!.dob != null) {
                      _dobController.text = DateFormat('yyyy-MM-dd').format(_patient!.dob!);
                    } else {
                      _dobController.clear();
                    }
                    _locationNameController.text = _patient!.locationName ?? '';
                    _latitudeController.text = _patient!.latitude?.toString() ?? '';
                    _longitudeController.text = _patient!.longitude?.toString() ?? '';
                  }
                });
              },
              tooltip: _isEditing ? 'Cancel Edit' : 'Edit My Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          // Use the declared _formKey here for validation
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _patient!.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      _patient!.email.isNotEmpty ? _patient!.email : 'No Email',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Patient Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(context, Icons.perm_identity, 'Patient ID', _patient!.id, isEditable: false),
                      // DOB and Age
                      if (_isEditing) ...[
                        InkWell(
                          onTap: () => _selectDateOfBirth(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dobController.text.isEmpty
                                  ? 'Select Date'
                                  : _dobController.text,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        if (_patient!.dob != null)
                          _buildInfoRow(context, Icons.calendar_today, 'Date of Birth', DateFormat('yyyy-MM-dd').format(_patient!.dob!), isEditable: false),
                        if (_patient!.calculatedAge != null)
                          _buildInfoRow(context, Icons.cake, 'Age', _patient!.calculatedAge.toString(), isEditable: false)
                        else
                          _buildInfoRow(context, Icons.cake, 'Age', _patient!.age, isEditable: false),
                      ],

                      _buildInfoRow(context, Icons.wc, 'Gender', _patient!.gender, isEditable: false),
                      _buildInfoRow(context, Icons.medical_information, 'Condition', _patient!.condition, isEditable: false),
                      _buildInfoRow(context, Icons.assignment_ind, 'Status', _patient!.status.toUpperCase(), isEditable: false),
                      if (_patient!.nurseId != null && _patient!.nurseId!.isNotEmpty)
                        _buildInfoRow(context, Icons.local_hospital, 'Assigned Nurse ID', _patient!.nurseId!, isEditable: false),

                      const SizedBox(height: 20),
                      Text(
                        'Contact & Address',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(context, Icons.phone, 'Contact', _patient!.contact, isEditable: _isEditing, controller: _contactController, keyboardType: TextInputType.phone, validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) return 'Required';
                        return null;
                      }),
                      _buildInfoRow(context, Icons.home, 'Address', _patient!.address, isEditable: _isEditing, controller: _addressController, maxLines: 3, validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) return 'Required';
                        return null;
                      }),

                      const SizedBox(height: 20),
                      Text(
                        'Emergency Contact Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(context, Icons.person_outline, 'Emergency Contact Name', _patient!.emergencyContactName ?? 'N/A', isEditable: _isEditing, controller: _emergencyContactNameController),
                      _buildInfoRow(context, Icons.phone_android, 'Emergency Contact Number', _patient!.emergencyContactNumber ?? 'N/A', isEditable: _isEditing, controller: _emergencyContactNumberController, keyboardType: TextInputType.phone),

                      const SizedBox(height: 20),
                      Text(
                        'Location Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Divider(height: 24),
                      // Location Name remains editable directly
                      _buildInfoRow(context, Icons.place, 'Location Name', _patient!.locationName ?? 'Not provided', isEditable: _isEditing, controller: _locationNameController),

                      // NEW: Button to open map for location selection
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _selectLocationOnMap,
                            icon: const Icon(Icons.map),
                            label: const Text('Select Location on Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Display Lat/Lng, but not directly editable via text field
                      _buildInfoRow(context, Icons.gps_fixed, 'Latitude', _patient!.latitude?.toStringAsFixed(6) ?? 'Not provided', isEditable: false),
                      _buildInfoRow(context, Icons.gps_not_fixed, 'Longitude', _patient!.longitude?.toStringAsFixed(6) ?? 'Not provided', isEditable: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Changes Button (only visible in patient self-edit mode)
              if (_isEditing && _isCurrentUserPatient)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
              if (!_isEditing) ...[ // Quick Actions and Nurse Edit button only in view mode
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      context,
                      label: 'Medical Records',
                      icon: Icons.receipt_long,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicalRecordsPage(
                              patientId: _patient!.id,
                              patientName: _patient!.name,
                            ),
                          ),
                        );
                        debugPrint('Medical Records pressed');
                      },
                      color: Colors.indigo,
                    ),
                    _buildActionButton(
                      context,
                      label: 'Prescriptions',
                      icon: Icons.medical_services,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientPrescriptionsScreen(
                              patientId: _patient!.id,
                              patientName: _patient!.name,
                            ),
                          ),
                        );
                        debugPrint('Prescriptions pressed');
                      },
                      color: Colors.purple,
                    ),
                    _buildActionButton(
                      context,
                      label: 'Notes',
                      icon: Icons.notes,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientNotesScreen(
                              patientId: _patient!.id,
                              patientName: _patient!.name,
                            ),
                          ),
                        );
                        debugPrint('Notes pressed');
                      },
                      color: Colors.orange,
                    ),
                    // Only show Add Appointment if a nurse is viewing this profile
                    if (_isAssignedNurse) // Changed condition to _isAssignedNurse
                      _buildActionButton(
                        context,
                        label: 'Add Appointment',
                        icon: Icons.calendar_month,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAppointmentScreen(
                                patientId: _patient!.id,
                                patientName: _patient!.name,
                              ),
                            ),
                          );
                          debugPrint('Add Appointment pressed - Navigating to AddAppointmentScreen');
                        },
                        color: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // NEW: Edit Patient Profile Button (for nurses)
                if (_isAssignedNurse)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_patient != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPatientScreen(patient: _patient!),
                            ),
                          );
                          debugPrint('Edit Patient Profile (Nurse) pressed - Navigating to EditPatientScreen');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Patient data not loaded. Cannot edit.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Patient Profile (Nurse)'), // Clarify for nurse
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build info rows (now conditional for editing)
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isEditable = false, TextEditingController? controller, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                isEditable
                    ? TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  validator: validator,
                )
                    : Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton(BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
