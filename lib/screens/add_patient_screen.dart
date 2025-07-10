import 'package:flutter/material.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  String? _selectedGender;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = picked.toLocal().toIso8601String().split('T')[0];
      });
    }
  }

  void _addPatient() {
    // Here you would implement the logic to save the new patient's data.
    // This would typically involve sending data to a backend database.
    print('Adding New Patient:');
    print('Full Name: ${_fullNameController.text}');
    print('Date of Birth: ${_dateOfBirthController.text}');
    print('Gender: ${_selectedGender ?? "N/A"}');
    print('Contact Number: ${_contactNumberController.text}');
    print('Email: ${_emailController.text}');
    print('Address: ${_addressController.text}');
    print('Medical History: ${_medicalHistoryController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient ${_fullNameController.text} added successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Optionally clear fields after adding
    _fullNameController.clear();
    _dateOfBirthController.clear();
    _contactNumberController.clear();
    _emailController.clear();
    _addressController.clear();
    _medicalHistoryController.clear();
    setState(() {
      _selectedGender = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
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
              },
            ),
            const SizedBox(height: 16),

            // Contact Number
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Address
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Medical History
            TextField(
              controller: _medicalHistoryController,
              decoration: const InputDecoration(
                labelText: 'Medical History (e.g., allergies, conditions)',
                hintText: 'e.g., "Allergies: Penicillin; Conditions: Diabetes"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.history),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 40),

            // Add Patient Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
}
