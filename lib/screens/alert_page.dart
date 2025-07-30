import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}


  String? _selectedPatientId; // Store patient ID
  String? _selectedPatientName; // Store patient name for display
  String? _selectedRecipientRole; // To whom the alert is primarily directed (Patient/Nurse)
  String _selectedAlertType = 'General Reminder';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoadingPatients = true;
  bool _isSchedulingAlert = false;

  List<Map<String, String>> _patients = []; // List of {'id': '...', 'name': '...'}

  final List<String> _alertTypes = ['General Reminder', 'Visit Reminder', 'Medication Alert', 'Activity Reminder', 'Emergency Alert'];
  final List<String> _recipientRoles = ['Patient', 'Nurse']; // Removed 'Doctor' to match previous decision

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
      print('Error fetching patients for alerts dropdown: $e');
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

  Future<void> _scheduleReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRecipientRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an alert recipient role.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedRecipientRole == 'Patient' && _selectedPatientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a patient for a patient-specific alert.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSchedulingAlert = true; // Start loading
      });

      try {
        // Combine date and time into a single DateTime object
        final DateTime scheduledDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Prepare alert data for Firestore
        Map<String, dynamic> alertData = {
          'description': _descriptionController.text.trim(),
          'patientId': _selectedPatientId, // Nullable if not patient-specific
          'patientName': _selectedPatientName, // Nullable if not patient-specific
          'recipientRole': _selectedRecipientRole,
          'alertType': _selectedAlertType,
          'scheduledDateTime': scheduledDateTime, // Firestore will convert this to Timestamp
          'isAcknowledged': false, // Default status
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid, // Record who created it
          // You might want to fetch and store the createdBy's name as well
          // 'createdByName': _currentUserName, // Requires fetching current user's name
        };

        // Add the alert data to the 'alerts' collection
        await FirebaseFirestore.instance.collection('alerts').add(alertData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder "${_descriptionController.text}" scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Optionally clear fields after scheduling
          _descriptionController.clear();
          setState(() {
            _selectedPatientId = null;
            _selectedPatientName = null;
            _selectedRecipientRole = null;
            _selectedAlertType = 'General Reminder';
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.now();
          });
        }
      } catch (e) {
        print('Error scheduling reminder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSchedulingAlert = false; // Stop loading
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule New Reminder/Activity'),
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
                'Reminder Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Description of the reminder/activity
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Reminder/Activity Description',
                  hintText: 'e.g., "Administer medication", "Follow-up visit"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Recipient Role Selection
              DropdownButtonFormField<String>(
                value: _selectedRecipientRole,
                hint: const Text('Alert Recipient Role'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: _recipientRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRecipientRole = newValue;
                    // If recipient is not 'Patient', clear selected patient
                    if (newValue != 'Patient') {
                      _selectedPatientId = null;
                      _selectedPatientName = null;
                    }
                  });
                },
                validator: (value) => value == null ? 'Please select a recipient role' : null,
              ),
              const SizedBox(height: 16),

              // Patient Selection (only visible if 'Patient' is selected as recipient role)
              if (_selectedRecipientRole == 'Patient') ...[
                _isLoadingPatients
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  hint: const Text('Select Patient'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
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
                      _selectedPatientName = _patients.firstWhere((p) => p['id'] == newValue)['name'];
                    });
                  },
                  validator: (value) => value == null ? 'Please select a patient' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Alert Type Selection
              DropdownButtonFormField<String>(
                value: _selectedAlertType,
                decoration: const InputDecoration(
                  labelText: 'Alert Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _alertTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAlertType = newValue!;
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
              const SizedBox(height: 40),

              // Schedule Button
              SizedBox(
                width: double.infinity,
                child: _isSchedulingAlert
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _scheduleReminder,
                  icon: const Icon(Icons.alarm_add),
                  label: const Text('Schedule Reminder'),
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
