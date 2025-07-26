import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // For getting nurse's location
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching patient locations
import 'package:firebase_auth/firebase_auth.dart'; // For current nurse's UID
import 'package:care_flow/models/patient.dart'; // Import Patient model
import 'package:care_flow/models/appointment.dart'; // Import Appointment model
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:flutter/foundation.dart'; // NEW: Re-added for kIsWeb
import 'package:http/http.dart' as http; // Import http for Directions API
import 'dart:math'; // Import math for Haversine formula
import 'dart:convert'; // Import for jsonDecode
// Required for accessing window/globalThis properties

const String googleDirectionsApiKey = 'AIzaSyDMFS9Xtlw7YAKZaPez2cnVn1-sON8ZVhk'; // TODO: Replace with your real API key

class NurseNavigationScreen extends StatefulWidget {
  const NurseNavigationScreen({super.key});

  @override
  State<NurseNavigationScreen> createState() => _NurseNavigationScreenState();
}

class _NurseNavigationScreenState extends State<NurseNavigationScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentNursePosition; // To store current nurse's location
  final Set<Marker> _markers = {}; // To store all markers (nurse + patients)
  final Set<Polyline> _polylines = {}; // To store polylines for routes
  String _locationError = ''; // Changed to non-nullable, initialized to empty string
  bool _isLoadingMap = true; // To track if map data is being loaded

  List<Patient> _allAssignedPatients = []; // To store all assigned patients
  Patient? _selectedPatientForNavigation; // The patient selected for directions
  String? _etaString; // Store ETA string
  String? _distanceString; // Store distance string

  bool _googleMapsApiLoaded = false; // Flag to track API readiness for web
  bool _isLocationDetermined = false; // Flag to track if nurse location has been determined

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsApiLoaded(); // Start by checking API status for web
  }

  // New method to check if Google Maps API is loaded, especially for web
  void _checkGoogleMapsApiLoaded() async {
    if (kIsWeb) {
      debugPrint('NurseNavigationScreen: Running on web. Checking Google Maps API readiness...');
      // For web, you may want to check for API readiness differently or just set as loaded
      setState(() {
        _googleMapsApiLoaded = true;
      });
      debugPrint('NurseNavigationScreen: Google Maps API confirmed loaded. _googleMapsApiLoaded: $_googleMapsApiLoaded');
      _loadMapData();
    } else {
      setState(() {
        _googleMapsApiLoaded = true;
      });
      debugPrint('NurseNavigationScreen: Not on web. Assuming Google Maps API loaded. _googleMapsApiLoaded: $_googleMapsApiLoaded');
      _loadMapData();
    }
  }

  // Combined method to load nurse's location and patient data
  Future<void> _loadMapData() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoadingMap = true;
      _locationError = ''; // Reset to empty string
      _markers.clear(); // Clear existing markers
      _polylines.clear(); // Clear existing polylines
      _allAssignedPatients.clear(); // Clear previous patient list
      _selectedPatientForNavigation = null; // Clear selected patient
      _etaString = null; // Clear ETA string
      _distanceString = null; // Clear distance string
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (currentContext.mounted) {
        _locationError = 'User not logged in. Cannot fetch patient locations.';
      }
      setState(() { _isLoadingMap = false; }); // Stop loading if no user
      return;
    }

    // 1. Get current nurse's location
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (currentContext.mounted) {
          _locationError = 'Location services are disabled. Please enable them.';
        }
        debugPrint('NurseNavigationScreen: Location services are disabled.');
        // Don't return here, proceed to fetch patients even if nurse location isn't available
      } else {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (currentContext.mounted) {
              _locationError = 'Location permissions denied. Cannot display your location.';
            }
            debugPrint('NurseNavigationScreen: Location permissions denied.');
            // Don't return here
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (currentContext.mounted) {
            _locationError = 'Location permissions are permanently denied. Please enable them from app settings.';
          }
          debugPrint('NurseNavigationScreen: Location permissions permanently denied.');
          // Don't return here
        }

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (currentContext.mounted) {
            setState(() {
              _currentNursePosition = LatLng(position.latitude, position.longitude);
              _markers.add(
                Marker(
                  markerId: const MarkerId('currentNurseLocation'),
                  position: _currentNursePosition!,
                  infoWindow: const InfoWindow(title: 'My Current Location (Nurse)'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Blue for nurse
                ),
              );
              _isLocationDetermined = true; // Mark nurse location as determined
            });
            debugPrint('NurseNavigationScreen: Nurse location obtained: $_currentNursePosition');
          }
        }
      }

      if (!currentContext.mounted) return;

      // Move camera to nurse's location if map is ready and location is available
      if (_mapController != null && _currentNursePosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentNursePosition!, 14.0),
        );
      }

    } catch (e) {
      debugPrint('NurseNavigationScreen: Error getting nurse location: $e');
      if (currentContext.mounted) {
        _locationError += '\nFailed to get your location: ${e.toString()}';
      }
    }

    // 2. Fetch patients assigned to the current nurse
    // 3. Fetch upcoming appointments for these patients
    try {
      QuerySnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('nurseId', isEqualTo: currentUser.uid)
          .get();

      if (!currentContext.mounted) return;

      // Populate _allAssignedPatients
      _allAssignedPatients = patientSnapshot.docs.map((doc) {
        return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Map to store patient ID to their upcoming appointment time
      Map<String, String> patientUpcomingAppointmentTimes = {};

      // Fetch upcoming appointments for all assigned patients
      if (_allAssignedPatients.isNotEmpty) {
        List<String> assignedPatientIds = _allAssignedPatients.map((patient) => patient.id).toList();
        QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', whereIn: assignedPatientIds)
            .where('assignedToId', isEqualTo: currentUser.uid) // Ensure it's assigned to this nurse
            .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now()) // Only upcoming appointments
            .orderBy('dateTime', descending: false) // Get the earliest upcoming
            .get();

        for (var appointmentDoc in appointmentSnapshot.docs) { // Corrected variable name from apptDoc
          final appointmentData = appointmentDoc.data() as Map<String, dynamic>; // Corrected variable name
          final appointment = Appointment.fromFirestore(appointmentData, appointmentDoc.id); // Corrected variable name
          // Only store the first upcoming appointment for each patient
          if (!patientUpcomingAppointmentTimes.containsKey(appointment.patientId)) {
            patientUpcomingAppointmentTimes[appointment.patientId] =
                DateFormat('MMM d, h:mm a').format(appointment.dateTime);
          }
        }
      }

      // Add markers for patients
      for (var patient in _allAssignedPatients) {
        if (patient.latitude != null && patient.longitude != null) {
          final LatLng patientLatLng = LatLng(patient.latitude!, patient.longitude!);
          String snippetText = patient.locationName ?? patient.address;

          // Add appointment time to snippet if available
          if (patientUpcomingAppointmentTimes.containsKey(patient.id)) {
            snippetText += '\nNext Visit: ${patientUpcomingAppointmentTimes[patient.id]}';
          } else {
            snippetText += '\nNo upcoming visits';
          }

          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(patient.id),
                position: patientLatLng,
                infoWindow: InfoWindow(
                  title: patient.name,
                  snippet: snippetText,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red for patients
              ),
            );
          });
        } else {
          debugPrint('NurseNavigationScreen: Patient ${patient.name} (ID: ${patient.id}) has no coordinates.');
        }
      }
    } catch (e) {
      debugPrint('NurseNavigationScreen: Error fetching patient or appointment locations: $e');
      if (currentContext.mounted) {
        _locationError += '\nFailed to load patient locations: ${e.toString()}';
      }
    } finally {
      if (currentContext.mounted) {
        setState(() {
          _isLoadingMap = false; // End loading after all data is fetched
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    debugPrint('NurseNavigationScreen: Map created.');

    // Only animate camera if a location is already determined
    if (_currentNursePosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentNursePosition!, 14.0),
      );
      debugPrint('NurseNavigationScreen: Camera animated to nurse position on map creation.');
    } else {
      // If nurse location not yet available, animate to a default
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(0.3392253, 32.5711991), 10.0), // Default to Kampala
      );
      debugPrint('NurseNavigationScreen: Nurse location not available, animating to default view.');
    }
  }

  // Method to show a bottom sheet for patient selection
  void _showPatientSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // Take 75% of screen height
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Select Patient for Navigation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent.shade700,
                ),
              ),
              const Divider(),
              Expanded(
                child: _allAssignedPatients.isEmpty
                    ? const Center(child: Text('No assigned patients found.'))
                    : ListView.builder(
                  itemCount: _allAssignedPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _allAssignedPatients[index];
                    return ListTile(
                      leading: const Icon(Icons.person_pin_circle, color: Colors.red),
                      title: Text(patient.name),
                      subtitle: Text(patient.locationName ?? patient.address),
                      onTap: () {
                        setState(() {
                          _selectedPatientForNavigation = patient;
                          _drawRoutePolyline(); // Draw polyline on selection
                          // Animate camera to selected patient's location
                          if (_mapController != null && patient.latitude != null && patient.longitude != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(LatLng(patient.latitude!, patient.longitude!), 15.0),
                            );
                          }
                        });
                        Navigator.pop(context); // Close the bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${patient.name} for navigation.')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Replace _drawRoutePolyline with real Directions API logic
  Future<void> _drawRoutePolyline() async {
    _polylines.clear();
    if (_currentNursePosition != null &&
        _selectedPatientForNavigation != null &&
        _selectedPatientForNavigation!.latitude != null &&
        _selectedPatientForNavigation!.longitude != null) {
      final origin = '${_currentNursePosition!.latitude},${_currentNursePosition!.longitude}';
      final destination = '${_selectedPatientForNavigation!.latitude},${_selectedPatientForNavigation!.longitude}';
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleDirectionsApiKey&mode=driving';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final polyline = route['overview_polyline']['points'];
            final points = _decodePolyline(polyline);
            final distance = route['legs'][0]['distance']['text'];
            final duration = route['legs'][0]['duration']['text'];
            setState(() {
              _polylines.add(Polyline(
                polylineId: const PolylineId('directions_route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ));
              _etaString = duration;
              _distanceString = distance;
            });
          } else {
            setState(() {
              _etaString = 'No route';
              _distanceString = '';
            });
          }
        } else {
          setState(() {
            _etaString = 'Error';
            _distanceString = '';
          });
        }
      } catch (e) {
        setState(() {
          _etaString = 'Error';
          _distanceString = '';
        });
      }
    }
  }

  // Polyline decoder for Google encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  // Method to launch external map application for directions
  Future<void> _launchMapDirections() async {
    if (_selectedPatientForNavigation == null ||
        _selectedPatientForNavigation!.latitude == null ||
        _selectedPatientForNavigation!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient with valid coordinates.')),
      );
      return;
    }

    final LatLng destination = LatLng(
      _selectedPatientForNavigation!.latitude!,
      _selectedPatientForNavigation!.longitude!,
    );

    // Google Maps URL scheme for directions
    // 'saddr' (source address/coordinates) can be omitted to use current location
    // 'daddr' (destination address/coordinates)
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';

    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch map for directions. URL: $googleMapsUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if essential data (API loaded, nurse location determined) is ready
    final bool essentialDataReady = _googleMapsApiLoaded && _isLocationDetermined;

    debugPrint('NurseNavigationScreen: Build method called. essentialDataReady: $essentialDataReady, _googleMapsApiLoaded: $_googleMapsApiLoaded, _isLocationDetermined: $_isLocationDetermined, _selectedPatientForNavigation: $_selectedPatientForNavigation');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse Navigation'),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoadingMap || !essentialDataReady // Show loading if map data or essential data is not ready
          ? const Center(child: CircularProgressIndicator())
          : _locationError.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _locationError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMapData, // Retry loading all data
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentNursePosition ?? const LatLng(0.3392253, 32.5711991),
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_selectedPatientForNavigation != null && _etaString != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ETA: ${_etaString ?? "--"}   Distance: ${_distanceString ?? "--"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Select Patient FAB
          FloatingActionButton.extended(
            heroTag: 'selectPatientFab', // Unique tag for multiple FABs
            onPressed: _showPatientSelectionSheet,
            label: const Text('Select Patient'),
            icon: const Icon(Icons.person_search),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          // Modified "Plan Route" / "Get Directions" FAB
          FloatingActionButton.extended(
            heroTag: 'planRouteFab', // Unique tag
            onPressed: _selectedPatientForNavigation != null
                ? _launchMapDirections
                : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a patient first to get directions.')),
              );
            },
            label: Text(
              _selectedPatientForNavigation != null
                  ? 'Get Directions to ${_selectedPatientForNavigation!.name}'
                  : 'Plan Route',
            ),
            icon: Icon(
              _selectedPatientForNavigation != null
                  ? Icons.directions
                  : Icons.alt_route,
            ),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position FABs to the right
    );
  }

  // Helper to calculate distance as a string
  String _calculateDistanceString(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;
    double dLat = (end.latitude - start.latitude) * (3.141592653589793 / 180.0);
    double dLon = (end.longitude - start.longitude) * (3.141592653589793 / 180.0);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(start.latitude * (3.141592653589793 / 180.0)) *
            cos(end.latitude * (3.141592653589793 / 180.0)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceKm = earthRadiusKm * c;
    return distanceKm.toStringAsFixed(2) + ' km';
  }
}
