import 'package:flutter/material.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedPatient;
  String? _selectedDoctor;
  String _appointmentType = 'Consultation';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Dummy data for dropdowns
  final List<String> _patients = ['John Kelly', 'Greg Teri', 'Anna Davis', 'Walter Reed'];
  final List<String> _doctors = ['Dr. Smith', 'Dr. Jones', 'Dr. Brown'];
  final List<String> _appointmentTypes = ['Consultation', 'Follow-up', 'Procedure', 'Vaccination'];

  @override
  void dispose() {
    _notesController.dispose();
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

  void _addAppointment() {
    // Here you would implement the logic to save the new appointment.
    // This would typically involve sending data to a backend database.
    print('Adding New Appointment:');
    print('Patient: ${_selectedPatient ?? "N/A"}');
    print('Doctor: ${_selectedDoctor ?? "N/A"}');
    print('Type: $_appointmentType');
    print('Date: ${_selectedDate.toLocal().toIso8601String().split('T')[0]}');
    print('Time: ${_selectedTime.format(context)}');
    print('Notes: ${_notesController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment for ${_selectedPatient ?? "N/A"} scheduled!'),
        backgroundColor: Colors.green,
      ),
    );

    // Optionally clear fields after adding
    _notesController.clear();
    setState(() {
      _selectedPatient = null;
      _selectedDoctor = null;
      _appointmentType = 'Consultation';
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Appointment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Patient Selection
            DropdownButtonFormField<String>(
              value: _selectedPatient,
              hint: const Text('Select Patient'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
              validator: (value) => value == null ? 'Please select a patient' : null,
            ),
            const SizedBox(height: 16),

            // Doctor Selection
            DropdownButtonFormField<String>(
              value: _selectedDoctor,
              hint: const Text('Select Doctor'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information),
              ),
              items: _doctors.map((String doctor) {
                return DropdownMenuItem<String>(
                  value: doctor,
                  child: Text(doctor),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDoctor = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a doctor' : null,
            ),
            const SizedBox(height: 16),

            // Appointment Type Selection
            DropdownButtonFormField<String>(
              value: _appointmentType,
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
                  _appointmentType = newValue!;
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
            const SizedBox(height: 24),

            // Notes for the appointment
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Appointment Notes (Optional)',
                hintText: 'e.g., "Patient prefers morning appointments"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // Add Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addAppointment,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Appointment'),
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
