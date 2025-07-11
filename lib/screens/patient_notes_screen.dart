import 'package:flutter/material.dart';

class PatientNotesScreen extends StatefulWidget {
  final String patientName; // To display whose notes are being viewed/added

  const PatientNotesScreen({super.key, required this.patientName});

  @override
  State<PatientNotesScreen> createState() => _PatientNotesScreenState();
}

class _PatientNotesScreenState extends State<PatientNotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  // Dummy list of notes for demonstration
  List<Map<String, String>> _notes = [
    {'date': '2025-07-08', 'content': 'Patient reported feeling better, no fever. Vital signs stable. Advised to continue medication as prescribed.', 'nurse': 'Nurse Jane'},
    {'date': '2025-07-05', 'content': 'Initial assessment: Patient presented with mild cough and fatigue. Recommended rest and hydration.', 'nurse': 'Nurse Jane'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty!')),
      );
      return;
    }

    setState(() {
      _notes.insert(0, { // Add new note to the beginning of the list
        'date': DateTime.now().toLocal().toIso8601String().split('T')[0],
        'content': _noteController.text.trim(),
        'nurse': 'Nurse Jane (Current User)', // In a real app, get current nurse's name
      });
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added successfully!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Notes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: _notes.isEmpty
                ? Center(
              child: Text('No notes recorded for ${widget.patientName} yet.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${note['date']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nurse: ${note['nurse']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note['content']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a new note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null, // Allows multiline input
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _addNote,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
