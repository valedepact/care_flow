import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NurseNavigationScreen extends StatefulWidget {
  const NurseNavigationScreen({super.key});

  @override
  State<NurseNavigationScreen> createState() => _NurseNavigationScreenState();
}

class _NurseNavigationScreenState extends State<NurseNavigationScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation; // To store the nurse's current location

  bool _isLoadingMap = true; // Set to true initially to fetch location
  String _mapErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Attempt to get current location on init
  }

  Future<void> _getCurrentLocation() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLoadingMap = true;
      _mapErrorMessage = '';
    });
    try {
      // Request location permissions
      LocationPermission permission = await Geolocator.requestPermission();
      if (!currentContext.mounted) return; // Check mounted after await

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _mapErrorMessage = 'Location permissions are denied. Please enable them in your device settings to use the map.';
          _isLoadingMap = false;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (currentContext.mounted) {
          setState(() {
            _mapErrorMessage = 'Location services are disabled. Please enable them to use the map.';
            _isLoadingMap = false;
          });
        }
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // High accuracy for navigation
      );

      if (!currentContext.mounted) return; // Check mounted again after position fetch

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingMap = false;
      });

      // If map controller is already initialized, move camera to current location
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (currentContext.mounted) {
        setState(() {
          _mapErrorMessage = 'Failed to get current location: ${e.toString()}. Please ensure location services are on and permissions are granted.';
          _isLoadingMap = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If current location is already available, animate camera to it
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
      );
    }
    debugPrint('GoogleMapController initialized: $_mapController');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse Navigation'),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoadingMap
          ? const Center(child: CircularProgressIndicator())
          : _mapErrorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 50, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _mapErrorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation, // Retry fetching location
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(0, 0), // Use current location, default to (0,0) if null
                    zoom: 14.0, // Initial zoom level
                  ),
                  myLocationEnabled: true, // Show user's current location dot
                  myLocationButtonEnabled: true, // Show button to recenter on user
                  markers: {
                    // Add a marker for the current location
                    if (_currentLocation != null) // Only add if location is available
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLocation!,
                        infoWindow: const InfoWindow(title: 'My Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                    // TODO: Add patient location markers here (fetch from Firestore)
                    // Example:
                    // Marker(
                    //   markerId: const MarkerId('patientLocation1'),
                    //   position: const LatLng(34.052235, -118.243683), // Example patient coordinates
                    //   infoWindow: const InfoWindow(title: 'Patient John Doe'),
                    // ),
                  },
                ),
                // You can add an overlay for patient selection or route planning
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _currentLocation != null
                            ? 'Current Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                            : 'Getting location...',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement navigation logic (e.g., select patient, get directions)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a patient to start navigation!')),
                  );
                },
                icon: const Icon(Icons.directions_car),
                label: const Text('Start Patient Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
