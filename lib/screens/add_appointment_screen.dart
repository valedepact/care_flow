import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:care_flow/models/appointment.dart'; // Import the Appointment model

class AddAppointmentScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

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
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  User? _currentUser;
  String? _currentUserName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    // Set initial date and time to current date/time
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = TimeOfDay.now().format(context);
  }

  @override
  void dispose() {
    _typeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
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

      setState(() {
        _isLoading = true;
      });

      try {
        // Combine date and time
        DateTime date = DateTime.parse(_dateController.text);
        TimeOfDay time = TimeOfDay.fromDateTime(DateFormat('h:mm a').parse(_timeController.text));
        DateTime appointmentDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final Appointment newAppointment = Appointment(
          id: '', // Firestore will generate this
          patientId: widget.patientId,
          patientName: widget.patientName,
          type: _typeController.text.trim(),
          dateTime: appointmentDateTime,
          location: _locationController.text.trim(),
          status: AppointmentStatus.upcoming, // Default to upcoming
          notes: _notesController.text.trim(),
          assignedToId: _currentUser!.uid,
          assignedToName: _currentUserName!,
          createdAt: DateTime.now(), // Will be overwritten by serverTimestamp in toFirestore
          statusColor: Appointment.getColorForStatus(AppointmentStatus.upcoming), // Initial color
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
        title: Text('Add Appointment for ${widget.patientName}'),
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

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Appointment Type (e.g., Check-up, Consultation)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter appointment type';
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
