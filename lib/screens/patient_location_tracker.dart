import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // For getting location
import 'package:firebase_auth/firebase_auth.dart'; // NEW: For current user UID
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: For Firestore operations

class PatientLocationTracker extends StatefulWidget {
  const PatientLocationTracker({super.key});

  @override
  State<PatientLocationTracker> createState() => _PatientLocationTrackerState();
}

class _PatientLocationTrackerState extends State<PatientLocationTracker> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition; // To store current user's location
  final Set<Marker> _markers = {}; // To store markers on the map
  String? _locationError; // To store any location-related errors
  bool _isLoadingLocation = true; // To track if location is being loaded

  User? _currentUser; // NEW: To hold the current authenticated user

  @override
  void initState() {
    super.initState();
    _initializeUserAndDeterminePosition(); // Initialize user then get location
  }

  Future<void> _initializeUserAndDeterminePosition() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _locationError = 'User not logged in. Cannot track location.';
          _isLoadingLocation = false;
        });
      }
      debugPrint('PatientLocationTracker: User not logged in.');
      return;
    }
    debugPrint('PatientLocationTracker: Current User UID: ${_currentUser!.uid}');
    await _determinePosition(); // Proceed to determine position if user is logged in
  }

  // Method to get current location and request permissions
  Future<void> _determinePosition() async {
    final currentContext = context; // Capture context
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    debugPrint('PatientLocationTracker: Attempting to determine position...');

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (currentContext.mounted) {
          setState(() {
            _locationError = 'Location services are disabled. Please enable them.';
            _isLoadingLocation = false;
          });
        }
        debugPrint('PatientLocationTracker: Location services are disabled.');
        return;
      }
      debugPrint('PatientLocationTracker: Location services enabled.');


      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('PatientLocationTracker: Location permissions denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (currentContext.mounted) {
            setState(() {
              _locationError = 'Location permissions are denied. Please grant permissions.';
              _isLoadingLocation = false;
            });
          }
          debugPrint('PatientLocationTracker: Location permissions denied after request.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (currentContext.mounted) {
          setState(() {
            _locationError = 'Location permissions are permanently denied. Please enable them from app settings.';
            _isLoadingLocation = false;
          });
        }
        debugPrint('PatientLocationTracker: Location permissions permanently denied.');
        return;
      }

      // When permissions are granted, get the current position.
      debugPrint('PatientLocationTracker: Permissions granted. Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!currentContext.mounted) {
        debugPrint('PatientLocationTracker: Widget unmounted after getting position.');
        return;
      }

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.clear(); // Clear existing markers before adding new ones
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'My Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Patient's location
          ),
        );
        _isLoadingLocation = false;
      });
      debugPrint('PatientLocationTracker: Current position obtained: $_currentPosition');


      // NEW: Save the current location to Firestore
      if (_currentUser != null && _currentPosition != null) {
        try {
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(_currentUser!.uid) // Use current user's UID as patient ID
              .update({
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
            'locationUpdatedAt': FieldValue.serverTimestamp(), // Timestamp of last update
          });
          debugPrint('PatientLocationTracker: Location saved to Firestore for UID: ${_currentUser!.uid}');
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text('Location updated successfully!')),
            );
          }
        } on FirebaseException catch (e) {
          debugPrint('PatientLocationTracker: Firebase Error saving location: $e');
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(content: Text('Failed to save location: ${e.message}'), backgroundColor: Colors.red),
            );
          }
        } catch (e) {
          debugPrint('PatientLocationTracker: Generic Error saving location: $e');
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(content: Text('Failed to save location: $e'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        debugPrint('PatientLocationTracker: Cannot save location: User or position is null.');
      }

      // Move camera to current location if map is ready
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
        );
        debugPrint('PatientLocationTracker: Camera animated to current position.');
      }
    } catch (e) {
      debugPrint('PatientLocationTracker: Error getting location: $e');
      if (currentContext.mounted) {
        setState(() {
          _locationError = 'Failed to get location: ${e.toString()}';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If current position is already determined, animate camera to it
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
      );
    }
    debugPrint('PatientLocationTracker: Map created.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location Tracker'), // Changed title for patient view
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _locationError != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeUserAndDeterminePosition, // Retry initialization and position
                child: const Text('Retry Location'),
              ),
            ],
          ),
        ),
      )
          : GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentPosition ?? const LatLng(0, 0), // Default to (0,0) if location not yet available
          zoom: 10.0,
        ),
        markers: _markers, // Display markers
        myLocationEnabled: true, // Show user's current location dot
        myLocationButtonEnabled: true, // Show button to recenter on user's location
      ),
    );
  }
}
