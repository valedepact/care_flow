import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectChatPartnerScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;

  const SelectChatPartnerScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<SelectChatPartnerScreen> createState() => _SelectChatPartnerScreenState();
}

class _SelectChatPartnerScreenState extends State<SelectChatPartnerScreen> {
  List<Map<String, dynamic>> _chatPartners = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchChatPartners();
  }

  Future<void> _fetchChatPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.currentUserRole == 'Nurse') {
        await _fetchPartnersForNurse();
      } else if (widget.currentUserRole == 'Patient') {
        await _fetchPartnersForPatient();
      } else {
        _errorMessage = 'Unknown user role. Cannot find chat partners.';
      }
    } catch (e) {
      debugPrint('Error fetching chat partners: $e');
      _errorMessage = 'Failed to load chat partners: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPartnersForNurse() async {
    List<Map<String, dynamic>> partners = [];

    // 1. Fetch all patients assigned to this nurse
    QuerySnapshot assignedPatientsSnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('nurseId', isEqualTo: widget.currentUserId)
        .get();

    for (var doc in assignedPatientsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      partners.add({
        'id': doc.id,
        'name': data['name'] ?? 'Unknown Patient',
        'role': 'Patient',
      });
    }

    // 2. Fetch all other nurses (excluding the current nurse)
    QuerySnapshot nursesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Nurse')
        .where(FieldPath.documentId, isNotEqualTo: widget.currentUserId)
        .get();

    for (var doc in nursesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      partners.add({
        'id': doc.id,
        'name': data['fullName'] ?? 'Unknown Nurse',
        'role': 'Nurse',
      });
    }

    // Remove duplicates if any (e.g., if a nurse is also listed as a patient for some reason, though unlikely)
    final uniquePartners = <String, Map<String, dynamic>>{};
    for (var p in partners) {
      uniquePartners[p['id']] = p;
    }

    if (mounted) {
      setState(() {
        _chatPartners = uniquePartners.values.toList();
        _chatPartners.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      });
    }
  }

  Future<void> _fetchPartnersForPatient() async {
    List<Map<String, dynamic>> partners = [];

    // 1. Find the patient document for the current user
    QuerySnapshot patientSnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where(FieldPath.documentId, isEqualTo: widget.currentUserId)
        .limit(1)
        .get();

    if (patientSnapshot.docs.isNotEmpty) {
      final patientData = patientSnapshot.docs.first.data() as Map<String, dynamic>;
      final assignedNurseId = patientData['nurseId'];

      if (assignedNurseId != null) {
        // 2. Fetch the assigned nurse's details
        DocumentSnapshot nurseDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(assignedNurseId)
            .get();

        if (nurseDoc.exists) {
          final nurseData = nurseDoc.data() as Map<String, dynamic>;
          partners.add({
            'id': nurseDoc.id,
            'name': nurseData['fullName'] ?? 'Assigned Nurse',
            'role': 'Nurse',
          });
        }
      } else {
        _errorMessage = 'You are not currently assigned to a nurse.';
      }
    } else {
      _errorMessage = 'Patient profile not found.';
    }

    if (mounted) {
      setState(() {
        _chatPartners = partners;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Chat Partner'),
        backgroundColor: Colors.indigo.shade700,
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
          : _chatPartners.isEmpty
          ? Center(
        child: Text(
          widget.currentUserRole == 'Nurse'
              ? 'No patients assigned or other nurses found.'
              : 'No assigned nurse found to chat with.',
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _chatPartners.length,
        itemBuilder: (context, index) {
          final partner = _chatPartners[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: Icon(
                  partner['role'] == 'Nurse' ? Icons.local_hospital : Icons.person,
                  color: Colors.indigo.shade700,
                ),
              ),
              title: Text(
                partner['name']!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Role: ${partner['role']}'),
              onTap: () {
                // Return the selected partner's ID and Name to the previous screen
                Navigator.pop(context, {
                  'id': partner['id'],
                  'name': partner['name'],
                });
              },
            ),
          );
        },
      ),
    );
  }
}
