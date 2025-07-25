import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:care_flow/models/patient.dart'; // Import the Patient model
import 'package:intl/intl.dart'; // For DateFormat
import 'package:care_flow/screens/select_location_on_map_screen.dart'; // NEW: Import SelectLocationOnMapScreen
import 'package:google_maps_flutter/google_maps_flutter.dart'; // NEW: Import LatLng

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Add New Patient'),
            Tab(text: 'Claim Patient'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AddNewPatientTab(), // Separate widget for adding new patient
          _ClaimPatientTab(), // Separate widget for claiming patients
        ],
      ),
    );
  }
}

// --- Add New Patient Tab ---
class _AddNewPatientTab extends StatefulWidget {
  const _AddNewPatientTab();

  @override
  State<_AddNewPatientTab> createState() => _AddNewPatientTabState();
}

class _AddNewPatientTabState extends State<_AddNewPatientTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController(); // NEW: For DOB
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose(); // Dispose DOB controller
    _genderController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _conditionController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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

  Future<void> _addNewPatient() async {
    final currentContext = context; // Capture context

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text('Error: Nurse not logged in.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        double? latitude = double.tryParse(_latitudeController.text.trim());
        double? longitude = double.tryParse(_longitudeController.text.trim());

        DateTime? dob;
        int? calculatedAge;
        if (_dateOfBirthController.text.isNotEmpty) {
          dob = DateTime.parse(_dateOfBirthController.text);
          calculatedAge = _calculateAge(dob);
        }

        final newPatient = Patient(
          id: '',
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          age: calculatedAge?.toString() ?? 'N/A', // Use calculatedAge for display 'age'
          gender: _genderController.text.trim(),
          contact: _contactController.text.trim(),
          address: _addressController.text.trim(),
          condition: _conditionController.text.trim(),
          medications: [],
          treatmentHistory: [],
          notes: [],
          imageUrls: [],
          lastVisit: 'N/A',
          emergencyContactName: _emergencyContactNameController.text.trim().isNotEmpty
              ? _emergencyContactNameController.text.trim()
              : null,
          emergencyContactNumber: _emergencyContactNumberController.text.trim().isNotEmpty
              ? _emergencyContactNumberController.text.trim()
              : null,
          createdAt: DateTime.now(),
          nurseId: null,
          status: 'unassigned',
          latitude: latitude,
          longitude: longitude,
          locationName: _locationNameController.text.trim().isNotEmpty
              ? _locationNameController.text.trim()
              : null,
          dob: dob, // NEW: Pass DOB
          calculatedAge: calculatedAge, // NEW: Pass calculatedAge
        );

        await FirebaseFirestore.instance.collection('patients').add(newPatient.toFirestore());

        if (!currentContext.mounted) return;

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Patient added successfully!'), backgroundColor: Colors.green),
        );
        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _dateOfBirthController.clear(); // Clear DOB
        _genderController.clear();
        _contactController.clear();
        _addressController.clear();
        _conditionController.clear();
        _emergencyContactNameController.clear();
        _emergencyContactNumberController.clear();
        _locationNameController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
      } on FirebaseException catch (e) {
        debugPrint('Firebase Error adding patient: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add patient: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint('Error adding patient: $e');
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add patient: $e'), backgroundColor: Colors.red),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Patient Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter patient\'s full name';
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
            ),
            const SizedBox(height: 16),

            // NEW: Date of Birth input
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

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _genderController,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter gender';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact number';
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
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Primary Condition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter primary condition';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Location Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.map, size: 30),
                  onPressed: _selectLocationFromMap, // Call the new function
                  tooltip: 'Select location on map',
                  color: Colors.purple.shade700,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter latitude';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter longitude';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Emergency Contact (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emergencyContactNameController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emergencyContactNumberController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _addNewPatient,
                icon: const Icon(Icons.save),
                label: const Text('Add Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
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
    );
  }
}

// --- Claim Patient Tab ---
class _ClaimPatientTab extends StatefulWidget {
  const _ClaimPatientTab();

  @override
  State<_ClaimPatientTab> createState() => _ClaimPatientTabState();
}

class _ClaimPatientTabState extends State<_ClaimPatientTab> {
  User? _currentUser;
  String? _currentNurseName;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in. Cannot claim patients.';
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
        _currentNurseName = userDoc.get('fullName') ?? 'Nurse';
      } else {
        _currentNurseName = 'Nurse';
      }
    } catch (e) {
      debugPrint('Error initializing user for claim tab: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load nurse data: $e';
        });
      }
    }
  }

  Future<void> _claimPatient(String patientId) async {
    final currentContext = context; // Capture context

    if (_currentUser == null || _currentNurseName == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error: Nurse not logged in.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('patients').doc(patientId).update({
        'nurseId': _currentUser!.uid,
        'status': 'assigned',
      });

      if (!currentContext.mounted) return;

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Patient claimed successfully!'), backgroundColor: Colors.green),
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error claiming patient: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to claim patient: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error claiming patient: $e');
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to claim patient: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Please log in as a nurse to claim patients.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .where('status', isEqualTo: 'unassigned')
          .where('nurseId', isNull: true) // Ensure nurseId is explicitly null
          .orderBy('createdAt', descending: true) // Show newest unassigned patients first
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error fetching unassigned patients stream: ${snapshot.error}');
          return Center(child: Text('Error loading patients: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No unassigned patients available for claiming.'),
          );
        }

        final unassignedPatients = snapshot.data!.docs.map((doc) {
          return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: unassignedPatients.length,
          itemBuilder: (context, index) {
            final patient = unassignedPatients[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Condition: ${patient.condition.isNotEmpty ? patient.condition : 'N/A'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Address: ${patient.address.isNotEmpty ? patient.address : 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (patient.locationName != null && patient.locationName!.isNotEmpty)
                      Text(
                        'Location Name: ${patient.locationName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (patient.latitude != null && patient.longitude != null)
                      Text(
                        'Coordinates: ${patient.latitude!.toStringAsFixed(4)}, ${patient.longitude!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _claimPatient(patient.id),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Claim Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
