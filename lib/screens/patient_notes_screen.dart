import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for current user
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/models/patient_note.dart'; // Import the new PatientNote model

class PatientNotesScreen extends StatefulWidget {
  final String patientId; // Now requires patientId
  final String patientName; // For display purposes

  const PatientNotesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientNotesScreen> createState() => _PatientNotesScreenState();
}

class _PatientNotesScreenState extends State<PatientNotesScreen> {
  List<PatientNote> _patientNotes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final GlobalKey<FormState> _addNoteFormKey = GlobalKey<FormState>();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteContentController = TextEditingController();
  bool _isAddingNote = false;

  User? _currentUser;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchNotes();
  }

  @override
  void dispose() {
    _noteTitleController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserAndFetchNotes() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in. Cannot fetch notes.';
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Unknown User';
      } else {
        _currentUserName = 'Unknown User'; // Fallback if user doc not found
      }
      await _fetchPatientNotes();
    } catch (e) {
      print('Error initializing user or fetching notes: $e');
      setState(() {
        _errorMessage = 'Failed to load user data or notes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('patientNotes')
          .where('patientId', isEqualTo: widget.patientId) // Filter by patient ID
          .orderBy('noteDate', descending: true) // Show most recent notes first
          .get();

      List<PatientNote> fetchedNotes = snapshot.docs.map((doc) {
        return PatientNote.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _patientNotes = fetchedNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patient notes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading patient notes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addPatientNote() async {
    if (_addNoteFormKey.currentState!.validate()) {
      if (_currentUser == null || _currentUserName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Cannot add note.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isAddingNote = true;
      });

      try {
        Map<String, dynamic> noteData = {
          'patientId': widget.patientId,
          'title': _noteTitleController.text.trim(),
          'content': _noteContentController.text.trim(),
          'noteDate': DateTime.now(), // Use current date for the note
          'createdBy': _currentUser!.uid,
          'createdByName': _currentUserName!,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('patientNotes').add(noteData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note added successfully!'), backgroundColor: Colors.green),
          );
          _noteTitleController.clear();
          _noteContentController.clear();
          Navigator.pop(context); // Close the add note dialog
          _fetchPatientNotes(); // Refresh the list of notes
        }
      } catch (e) {
        print('Error adding patient note: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add note: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingNote = false;
          });
        }
      }
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Patient Note'),
          content: Form(
            key: _addNoteFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _noteTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteContentController,
                    decoration: const InputDecoration(
                      labelText: 'Note Content',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter note content';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            _isAddingNote
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _addPatientNote,
              child: const Text('Add Note'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Notes'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
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
          : _patientNotes.isEmpty
          ? Center(
        child: Text('No notes found for ${widget.patientName}.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _patientNotes.length,
        itemBuilder: (context, index) {
          final note = _patientNotes[index];
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
                    note.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(note.noteDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Created By: ${note.createdByName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Implement Edit/Delete Note functionality
                        print('View/Edit Note ID: ${note.id}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Viewing/Editing note: ${note.title}')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Note'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        label: const Text('Add Note'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
