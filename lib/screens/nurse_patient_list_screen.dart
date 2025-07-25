import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:care_flow/models/patient.dart';
import 'package:care_flow/screens/patient_profile_page.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator for distance calculation
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import LatLng

class NursePatientListScreen extends StatefulWidget {
  final String nurseId;

  const NursePatientListScreen({super.key, required this.nurseId});

  @override
  State<NursePatientListScreen> createState() => _NursePatientListScreenState();
}

class _NursePatientListScreenState extends State<NursePatientListScreen> {
  LatLng? _currentNurseLocation; // Nurse's current location
  List<Patient> _patientsWithDistance = []; // Patients with calculated distances
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientsAndNurseLocation();
  }

  Future<void> _fetchPatientsAndNurseLocation() async {
    final currentContext = context;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.nurseId.isEmpty) {
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'Nurse ID not provided. Please log in again.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1. Get Nurse's Current Location
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (currentContext.mounted) {
          _errorMessage = 'Location services are disabled. Please enable them to sort patients by distance.';
        }
        debugPrint('NursePatientListScreen: Location services disabled.');
        // Continue without location if disabled, but inform user
      } else {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (currentContext.mounted) {
              _errorMessage = 'Location permissions denied. Cannot sort patients by distance.';
            }
            debugPrint('NursePatientListScreen: Location permissions denied.');
            // Continue without location if denied
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (currentContext.mounted) {
            _errorMessage = 'Location permissions are permanently denied. Cannot sort patients by distance.';
          }
          debugPrint('NursePatientListScreen: Location permissions permanently denied.');
          // Continue without location if permanently denied
        }

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (currentContext.mounted) {
            setState(() {
              _currentNurseLocation = LatLng(position.latitude, position.longitude);
            });
            debugPrint('NursePatientListScreen: Nurse location obtained: $_currentNurseLocation');
          }
        }
      }

      if (!currentContext.mounted) return;

      // 2. Fetch Patients assigned to this Nurse
      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: widget.nurseId)
          .get();

      if (!currentContext.mounted) return;

      List<Patient> fetchedPatients = patientSnapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // 3. Calculate Distance and Sort
      if (_currentNurseLocation != null) {
        for (var patient in fetchedPatients) {
          if (patient.latitude != null && patient.longitude != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _currentNurseLocation!.latitude,
              _currentNurseLocation!.longitude,
              patient.latitude!,
              patient.longitude!,
            );
            // Store distance in patient object (or a wrapper class/map) for sorting
            // For simplicity, we'll store it in a temporary map for sorting
            patient.distanceFromNurse = distanceInMeters / 1000; // Convert to kilometers
          } else {
            patient.distanceFromNurse = double.infinity; // Put patients without coords at the end
          }
        }
        // Sort by distance
        fetchedPatients.sort((a, b) {
          // Handle null/infinity distances for robust sorting
          if (a.distanceFromNurse == null && b.distanceFromNurse == null) return 0;
          if (a.distanceFromNurse == null) return 1; // Nulls go to end
          if (b.distanceFromNurse == null) return -1; // Nulls go to end
          return a.distanceFromNurse!.compareTo(b.distanceFromNurse!);
        });
        debugPrint('NursePatientListScreen: Patients sorted by distance.');
      } else {
        debugPrint('NursePatientListScreen: Nurse location not available, skipping distance calculation and sorting.');
        // If nurse location isn't available, sort by name as a fallback
        fetchedPatients.sort((a, b) => a.name.compareTo(b.name));
      }

      if (currentContext.mounted) {
        setState(() {
          _patientsWithDistance = fetchedPatients;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('NursePatientListScreen: Error fetching patients or calculating distances: $e');
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'Failed to load patients or calculate distances: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Claimed Patients'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPatientsAndNurseLocation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _patientsWithDistance.isEmpty
          ? const Center(
        child: Text('You have not claimed any patients yet.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _patientsWithDistance.length,
        itemBuilder: (context, index) {
          final patient = _patientsWithDistance[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientProfilePage(
                      patientId: patient.id,
                      patientName: patient.name,
                    ),
                  ),
                );
                debugPrint('Opening patient profile for ${patient.name} (ID: ${patient.id})');
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Condition: ${patient.condition.isNotEmpty ? patient.condition : 'N/A'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Age: ${patient.age}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Gender: ${patient.gender}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Contact: ${patient.contact}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (patient.distanceFromNurse != null && patient.distanceFromNurse != double.infinity)
                      Text(
                        'Distance: ${patient.distanceFromNurse!.toStringAsFixed(2)} km',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      )
                    else if (patient.latitude == null || patient.longitude == null)
                      Text(
                        'Distance: Location data missing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
