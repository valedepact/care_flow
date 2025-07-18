import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // For getting location

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

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Get user's current location on init
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
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (currentContext.mounted) {
            setState(() {
              _locationError = 'Location permissions are denied. Please grant permissions.';
              _isLoadingLocation = false;
            });
          }
          debugPrint('Location permissions are denied.');
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
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      // When permissions are granted, get the current position.
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!currentContext.mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'My Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Nurse's location
          ),
        );
        _isLoadingLocation = false;
      });

      // Move camera to current location if map is ready
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Location Tracker'),
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
              Icon(Icons.location_off, size: 50, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _determinePosition,
                child: Text('Retry Location'),
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
