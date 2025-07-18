import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current nurse's UID
import 'package:intl/intl.dart'; // For date formatting

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> with SingleTickerProviderStateMixin {
  // Controllers for 'Add New Patient' tab
  final GlobalKey<FormState> _addPatientFormKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();

  String? _selectedGender;
  bool _isLoadingAddPatient = false; // Loading for adding new patient

  final List<String> _genders = ['Male', 'Female', 'Other'];

  // For 'Claim Patient' tab
  // Replaced single boolean with a Set for per-patient loading state
  final Set<String> _loadingClaimingIds = {};
  String? _currentNurseId; // To store the logged-in nurse's UID

  // Tab Controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentNurseId(); // Get the current nurse's ID on init
  }

  // Fetch the current logged-in nurse's UID
  void _getCurrentNurseId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentNurseId = user.uid;
      });
      debugPrint('Current Nurse ID: $_currentNurseId');
    } else {
      debugPrint('No nurse user logged in.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nurse logged in. Please log in to claim patients.')),
        );
      }
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
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _tabController.dispose(); // Dispose tab controller
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Pre-fill with existing date if available, otherwise default to 20 years ago
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now().subtract(const Duration(days: 365 * 20))
          : DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked); // Format for display
      });
    }
  }

  Future<void> _addPatient() async {
    if (_addPatientFormKey.currentState!.validate()) {
      setState(() {
        _isLoadingAddPatient = true; // Start loading for add patient
      });

      try {
        DateTime? dob;
        int? age;
        if (_dateOfBirthController.text.isNotEmpty) {
          dob = DateTime.parse(_dateOfBirthController.text);
          DateTime today = DateTime.now();
          age = today.year - dob.year;
          if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
        }

        // Create a map of patient data to save to Firestore
        Map<String, dynamic> patientData = {
          'name': _fullNameController.text.trim(),
          'dob': dob != null ? Timestamp.fromDate(dob) : null, // Store DOB as Timestamp
          'age': age, // Store calculated age
          'gender': _selectedGender ?? 'N/A',
          'contact': _contactNumberController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'condition': _conditionController.text.trim(),
          'medications': [],
          'treatmentHistory': [],
          'notes': [],
          'imageUrls': [],
          'lastVisit': 'N/A',
          'nextAppointmentId': null,
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'nurseId': null, // New patients are unassigned by default
          'status': 'unassigned', // New patients are unassigned by default
        };

        // Add the patient data to the 'patients' collection in Firestore
        final docRef = await FirebaseFirestore.instance.collection('patients').add(patientData);
        debugPrint('Patient added with ID: ${docRef.id}'); // Log new document ID

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${_fullNameController.text} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear fields and reset form state after adding
        _fullNameController.clear();
        _dateOfBirthController.clear();
        _contactNumberController.clear();
        _emailController.clear();
        _addressController.clear();
        _conditionController.clear();
        _emergencyContactNameController.clear();
        _emergencyContactNumberController.clear();
        setState(() {
          _selectedGender = null;
          _addPatientFormKey.currentState?.reset(); // Reset form validation state
        });
      } catch (e) {
        debugPrint('Error adding patient: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingAddPatient = false; // Stop loading
          });
        }
      }
    }
  }

  // Function to claim an unassigned patient
  Future<void> _claimPatient(String patientDocId) async {
    if (_currentNurseId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Nurse ID not found. Please log in again.')),
        );
      }
      return;
    }

    setState(() {
      _loadingClaimingIds.add(patientDocId); // Add patient ID to loading set
    });

    try {
      await FirebaseFirestore.instance.collection('patients').doc(patientDocId).update({
        'nurseId': _currentNurseId,
        'status': 'assigned',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient claimed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error claiming patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingClaimingIds.remove(patientDocId); // Remove patient ID from loading set
        });
      }
    }
  }

  // Helper method to build the 'Add New Patient' form
  Widget _buildAddPatientForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _addPatientFormKey,
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

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.next, // Next action
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
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

            // Gender Selection
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
                FocusScope.of(context).nextFocus(); // Move focus after selection
              },
              validator: (value) => value == null ? 'Please select gender' : null,
            ),
            const SizedBox(height: 16),

            // Contact Number
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
                // Basic phone number validation (digits only, min length)
                if (!RegExp(r'^[0-9]+$').hasMatch(value) || value.length < 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
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

            // Address
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

            // Condition
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Condition (e.g., Diabetes, Hypertension)',
                hintText: 'e.g., "Type 2 Diabetes"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
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
              textInputAction: TextInputAction.done, // Last field, so 'done'
              onFieldSubmitted: (_) => _addPatient(), // Submit form on done
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: _isLoadingAddPatient
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _addPatient,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Patient'),
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
    );
  }

  // Helper method to build the 'Claim Patient' list view
  Widget _buildClaimPatientList() {
    if (_currentNurseId == null) {
      return const Center(
        child: Text('Please log in as a nurse to claim patients.'),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Unassigned Patients',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .where('status', isEqualTo: 'unassigned')
                .where('nurseId', isNull: true) // Ensure nurseId is null
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint('Error fetching unassigned patients: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No unassigned patients found.'));
              }

              final unassignedPatients = snapshot.data!.docs;

              return ListView.builder(
                itemCount: unassignedPatients.length,
                itemBuilder: (context, index) {
                  final patientDoc = unassignedPatients[index];
                  final patientData = patientDoc.data() as Map<String, dynamic>;
                  final patientName = patientData['name'] ?? 'Unknown Patient';
                  final patientCondition = patientData['condition'] ?? 'N/A';
                  final patientId = patientDoc.id; // Get the patient's document ID

                  // Check if this specific patient's claim button is loading
                  final bool isClaiming = _loadingClaimingIds.contains(patientId);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: Text(
                          patientName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        patientName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Condition: $patientCondition'),
                      trailing: isClaiming // Use per-patient loading state
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: () => _claimPatient(patientId), // Pass the patient ID
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Claim'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Add New Patient', icon: Icon(Icons.person_add)),
            Tab(text: 'Claim Patient', icon: Icon(Icons.assignment_ind)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddPatientForm(), // Tab 1: Add New Patient
          _buildClaimPatientList(), // Tab 2: Claim Patient
        ],
      ),
    );
  }
}
