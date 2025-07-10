import 'package:flutter/material.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPatient; // For nurses to select a patient
  String? _selectedRecipientRole; // To whom the alert is primarily directed (Patient/Nurse)
  String _selectedAlertType = 'General Reminder';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Dummy data for patient selection
  final List<String> _patients = ['John Kelly', 'Greg Teri', 'Anna Davis', 'Walter Reed'];
  final List<String> _alertTypes = ['General Reminder', 'Visit Reminder', 'Medication Alert', 'Activity Reminder'];
  final List<String> _recipientRoles = ['Patient', 'Nurse', 'Doctor']; // Can be expanded

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  void _scheduleReminder() {
    // Here you would implement the logic to save/send the reminder.
    // This could involve sending data to a backend, scheduling local notifications, etc.
    print('Scheduling Reminder:');
    print('Description: ${_descriptionController.text}');
    print('Patient: ${_selectedPatient ?? "N/A"}');
    print('Recipient Role: ${_selectedRecipientRole ?? "N/A"}');
    print('Alert Type: $_selectedAlertType');
    print('Date: ${_selectedDate.toLocal().toIso8601String().split('T')[0]}');
    print('Time: ${_selectedTime.format(context)}');

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder "${_descriptionController.text}" scheduled!'),
        backgroundColor: Colors.green,
      ),
    );

    // Optionally clear fields after scheduling
    _descriptionController.clear();
    setState(() {
      _selectedPatient = null;
      _selectedRecipientRole = null;
      _selectedAlertType = 'General Reminder';
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
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
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Reminder/Activity Description',
                hintText: 'e.g., "Administer medication", "Follow-up visit"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Patient Selection (primarily for nurses)
            DropdownButtonFormField<String>(
              value: _selectedPatient,
              hint: const Text('Select Patient (Optional)'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              items: _patients.map((String patient) {
                return DropdownMenuItem<String>(
                  value: patient,
                  child: Text(patient),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPatient = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

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
                });
              },
              validator: (value) => value == null ? 'Please select a recipient role' : null,
            ),
            const SizedBox(height: 24),

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
                        '${_selectedDate.toLocal().toIso8601String().split('T')[0]}',
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
              child: ElevatedButton.icon(
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
    );
  }
}
