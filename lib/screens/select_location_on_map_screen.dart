import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class SelectLocationOnMapScreen extends StatefulWidget {
  // Optional initial location to display on the map
  final LatLng? initialLocation;
  final String? initialLocationName;

  const SelectLocationOnMapScreen({
    super.key,
    this.initialLocation,
    this.initialLocationName,
  });

  @override
  State<SelectLocationOnMapScreen> createState() => _SelectLocationOnMapScreenState();
}

class _SelectLocationOnMapScreenState extends State<SelectLocationOnMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  String? _errorMessage;
  final TextEditingController _locationNameController = TextEditingController();

  bool _googleMapsApiLoaded = false; // Flag to track API readiness
  bool _isLocationDetermined = false; // Flag to track if location has been determined
  bool _isMapInitialized = false; // Flag to track if map controller is ready

  @override
  void initState() {
    super.initState();
    _locationNameController.text = widget.initialLocationName ?? '';
    debugPrint('SelectLocationOnMapScreen: initState called.');
    _checkGoogleMapsApiLoaded(); // Start by checking API status
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _mapController?.dispose();
    debugPrint('SelectLocationOnMapScreen: dispose called.');
    super.dispose();
  }

  // New method to check if Google Maps API is loaded, especially for web
  void _checkGoogleMapsApiLoaded() async {
    if (kIsWeb) {
      debugPrint('SelectLocationOnMapScreen: Running on web. Checking Google Maps API readiness...');
      // For web, you may want to check for API readiness differently or just set as loaded
      setState(() {
        _googleMapsApiLoaded = true;
      });
      debugPrint('SelectLocationOnMapScreen: Google Maps API confirmed loaded. _googleMapsApiLoaded:  [38;5;2m$_googleMapsApiLoaded [0m');
      _initLocationAndMap();
    } else {
      setState(() {
        _googleMapsApiLoaded = true;
      });
      debugPrint('SelectLocationOnMapScreen: Not on web. Assuming Google Maps API loaded. _googleMapsApiLoaded: $_googleMapsApiLoaded');
      _initLocationAndMap();
    }
  }

  // Combined initialization logic for location and map
  Future<void> _initLocationAndMap() async {
    debugPrint('SelectLocationOnMapScreen: _initLocationAndMap called.');
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _addMarker(_selectedLocation!, 'selectedLocation', 'Selected Location');
      setState(() {
        _isLocationDetermined = true; // Mark location as determined
      });
      debugPrint('SelectLocationOnMapScreen: Initial location provided. _isLocationDetermined: $_isLocationDetermined');
    } else {
      await _determineCurrentPosition(); // Try to get current position if no initial location is provided
      debugPrint('SelectLocationOnMapScreen: Attempted to determine current position. _isLocationDetermined: $_isLocationDetermined');
    }
  }

  // Method to get current location and request permissions
  Future<void> _determineCurrentPosition() async {
    final currentContext = context; // Capture context
    setState(() {
      _isLocationDetermined = false; // Reset location determined flag
      _errorMessage = null;
    });
    debugPrint('SelectLocationOnMapScreen: Attempting to determine current position...');

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (currentContext.mounted) {
          _errorMessage = 'Location services are disabled. Please enable them.';
        }
        debugPrint('SelectLocationOnMapScreen: Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('SelectLocationOnMapScreen: Location permissions denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (currentContext.mounted) {
            _errorMessage = 'Location permissions are denied. Please grant permissions.';
          }
          debugPrint('SelectLocationOnMapScreen: Location permissions denied after request.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (currentContext.mounted) {
          _errorMessage = 'Location permissions are permanently denied. Please enable them from app settings.';
        }
        debugPrint('SelectLocationOnMapScreen: Location permissions permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (!currentContext.mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_selectedLocation!, 'currentLocation', 'Your Current Location');
        _isLocationDetermined = true; // Mark location as determined
      });
      debugPrint('SelectLocationOnMapScreen: Current position obtained: $_selectedLocation. _isLocationDetermined: $_isLocationDetermined');

      if (_mapController != null && _selectedLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
        );
        debugPrint('SelectLocationOnMapScreen: Camera animated to current position.');
      }
    } catch (e) {
      debugPrint('SelectLocationOnMapScreen: Error getting location: $e');
      if (currentContext.mounted) {
        setState(() {
          _errorMessage = 'Failed to get current location: ${e.toString()}';
          _isLocationDetermined = true; // Still mark as determined to stop loading, but show error
        });
      }
    } finally {
      if (mounted) {
        // Ensure _isLocationDetermined is set to true even if there's an error
        // to stop the initial loading indicator and show the error message.
        setState(() {
          _isLocationDetermined = true;
        });
      }
    }
  }

  void _addMarker(LatLng position, String markerId, String title) {
    _markers.clear(); // Clear existing marker
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
      ),
    );
    debugPrint('SelectLocationOnMapScreen: Marker added at $position. Total markers: ${_markers.length}');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapInitialized = true; // Mark map as initialized
    });
    debugPrint('SelectLocationOnMapScreen: Map created and initialized. _isMapInitialized: $_isMapInitialized');

    // Only animate camera if a location is already selected
    if (_selectedLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
      );
      debugPrint('SelectLocationOnMapScreen: Camera animated to selected location on map creation.');
    } else {
      // If no location is selected yet, animate to a default or wait for location to be determined
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(0, 0), 2.0), // Default view
      );
      debugPrint('SelectLocationOnMapScreen: No selected location yet, animating to default view.');
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _addMarker(latLng, 'tappedLocation', 'Selected Location');
      debugPrint('SelectLocationOnMapScreen: Map tapped, new location: $latLng');
    });
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map or use current location.')),
      );
      return;
    }

    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'locationName': _locationNameController.text.trim(),
    });
    debugPrint('SelectLocationOnMapScreen: Location confirmed and popped.');
  }

  @override
  Widget build(BuildContext context) {
    // Determine if essential data (API loaded, location determined) is ready
    final bool essentialDataReady = _googleMapsApiLoaded && _isLocationDetermined;

    debugPrint('SelectLocationOnMapScreen: Build method called. essentialDataReady: $essentialDataReady, _googleMapsApiLoaded: $_googleMapsApiLoaded, _isLocationDetermined: $_isLocationDetermined, _isMapInitialized: $_isMapInitialized, _selectedLocation: $_selectedLocation');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determineCurrentPosition,
            tooltip: 'Use Current Location',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !essentialDataReady // Only show loading if essential data is NOT ready
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _determineCurrentPosition,
                      child: const Text('Retry Location'),
                    ),
                  ],
                ),
              ),
            )
                : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(0.3392253, 32.5711991), // Use obtained location or a default Kampala coordinate
                zoom: 15.0, // Start with a reasonable zoom level
              ),
              markers: _markers, // Display markers
              onTap: _onMapTap, // Allow user to tap to select location
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Hide default button as we have our own
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _locationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name (e.g., Home, Work, Clinic)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedLocation != null
                      ? 'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                      : 'Tap on the map to select a location, or use current location.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
