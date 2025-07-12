import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:care_flow/models/prescription.dart'; // Correctly import the Prescription model

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AddPrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  User? _currentUser;
  String? _currentUserName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default start date to today
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentUser() async {
    final currentContext = context; // Capture context

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('User not logged in. Cannot add prescription.'), backgroundColor: Colors.red),
        );
        Navigator.pop(currentContext); // Use captured context
      }
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (!currentContext.mounted) return; // Use captured context

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Unknown Prescriber';
      } else {
        _currentUserName = 'Unknown Prescriber';
      }
    } catch (e) {
      debugPrint('Error fetching current user name: $e');
      if (currentContext.mounted) { // Use captured context
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _addPrescription() async {
    final currentContext = context; // Capture context

    if (_formKey.currentState!.validate()) {
      if (_currentUser == null || _currentUserName == null) {
        if (currentContext.mounted) { // Use captured context
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('User not authenticated. Cannot add prescription.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        DateTime startDate = DateTime.parse(_startDateController.text);
        DateTime? endDate;
        if (_endDateController.text.isNotEmpty) {
          endDate = DateTime.parse(_endDateController.text);
        }

        // Using the Prescription model imported from models/prescription.dart
        final Prescription newPrescription = Prescription(
          id: '', // Firestore will generate this
          patientId: widget.patientId,
          medicationName: _medicationNameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _frequencyController.text.trim(),
          startDate: startDate,
          endDate: endDate,
          instructions: _instructionsController.text.trim(), // This is correct based on models/prescription.dart
          prescribedBy: _currentUser!.uid,
          prescribedByName: _currentUserName!, // This is correct based on models/prescription.dart
          prescribedDate: startDate, // Using startDate as prescribedDate
          createdAt: DateTime.now(), // Will be overwritten by serverTimestamp in toFirestore
        );

        await FirebaseFirestore.instance.collection('prescriptions').add(newPrescription.toFirestore());

        if (!currentContext.mounted) return; // Use captured context

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Prescription added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(currentContext); // Use captured context
      } on FirebaseException catch (e) {
        debugPrint('Firebase Error adding prescription: $e');
        if (currentContext.mounted) { // Use captured context
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add prescription: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint('Error adding prescription: $e');
        if (currentContext.mounted) { // Use captured context
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to add prescription: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) { // This setState is for the screen itself, so `mounted` is fine here
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
        title: Text('Add Prescription for ${widget.patientName}'),
        backgroundColor: Colors.teal.shade700, // A distinct color for prescriptions
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
                'Prescription Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _medicationNameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg, 1 tablet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'e.g., Once daily, Every 8 hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              InkWell(
                onTap: () => _selectDate(context, _startDateController),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDateController.text.isEmpty
                        ? 'Select Date'
                        : _startDateController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date (Optional)
              InkWell(
                onTap: () => _selectDate(context, _endDateController),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    _endDateController.text.isEmpty
                        ? 'Select Date'
                        : _endDateController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions',
                  hintText: 'e.g., Take with food, Do not crush',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _addPrescription,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
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
