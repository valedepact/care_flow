import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For GoogleMap widget
import 'package:care_flow/services/map_service.dart'; // Import your MapService
import 'package:geolocator/geolocator.dart'; // For LocationPermission

class NurseNavigationScreen extends StatefulWidget {
  const NurseNavigationScreen({super.key});

  @override
  State<NurseNavigationScreen> createState() => _NurseNavigationScreenState();
}

class _NurseNavigationScreenState extends State<NurseNavigationScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final MapService _mapService = MapService(); // Instantiate MapService

  // Default camera position (e.g., a central point in Kampala, Uganda)
  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(0.347596, 32.582520), // Kampala, Uganda coordinates
    zoom: 12,
  );

  LatLng? _currentLatLng;
  String _currentLocationAddress = 'Fetching current location...';
  String _navigationStatus = 'Enter a destination to get directions.';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndSetMap();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  // Fetches current location and updates map camera
  Future<void> _getCurrentLocationAndSetMap() async {
    final LatLng? location = await _mapService.getCurrentLocation();
    if (mounted) {
      if (location != null) {
        setState(() {
          _currentLatLng = location;
          _currentLocationAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: location,
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        });
        await _mapService.animateCameraToPosition(location);
      } else {
        setState(() {
          _currentLocationAddress = 'Could not get current location.';
        });
      }
    }
  }

  // Simulates getting directions and displaying them on the map
  void _getDirections() async {
    if (_destinationController.text.trim().isEmpty) {
      setState(() {
        _navigationStatus = 'Please enter a destination.';
      });
      return;
    }

    if (_currentLatLng == null) {
      setState(() {
        _navigationStatus = 'Cannot get directions: Current location not available.';
      });
      return;
    }

    setState(() {
      _navigationStatus = 'Getting directions to ${_destinationController.text.trim()}...';
      _markers.clear(); // Clear existing markers
      _polylines.clear(); // Clear existing polylines
    });

    // Dummy destination for demonstration. In a real app, you'd geocode the address.
    // For now, let's use a fixed dummy destination.
    final LatLng dummyDestination = LatLng(0.3150, 32.5816); // A nearby location in Kampala

    // Add markers for origin and destination
    _markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: _currentLatLng!,
        infoWindow: const InfoWindow(title: 'Origin'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: dummyDestination,
        infoWindow: InfoWindow(title: _destinationController.text.trim()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Simulate getting optimized route (currently returns straight line)
    final List<LatLng> routePoints = await _mapService.getOptimizedRoute(
      _currentLatLng!,
      dummyDestination,
      [], // No waypoints for simplicity
    );

    // Simulate getting route details (ETA, traffic)
    final Map<String, dynamic> routeDetails = await _mapService.getRouteDetails(
      _currentLatLng!,
      dummyDestination,
    );

    if (mounted) {
      setState(() {
        _navigationStatus = 'ETA: ${routeDetails['eta']}, Traffic: ${routeDetails['traffic_alerts']}';

        // Add polyline for the route
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      });

      // Animate camera to show both origin and destination
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentLatLng!.latitude < dummyDestination.latitude ? _currentLatLng!.latitude : dummyDestination.latitude,
          _currentLatLng!.longitude < dummyDestination.longitude ? _currentLatLng!.longitude : dummyDestination.longitude,
        ),
        northeast: LatLng(
          _currentLatLng!.latitude > dummyDestination.latitude ? _currentLatLng!.latitude : dummyDestination.latitude,
          _currentLatLng!.longitude > dummyDestination.longitude ? _currentLatLng!.longitude : dummyDestination.longitude,
        ),
      );
      _mapService.animateCameraToPosition(bounds.northeast); // Animate to a corner of the bounds
      // For a more robust fit, you'd use _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding))
      // which requires the _mapController to be directly exposed or managed by the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation & Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Your Route',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Location Display
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.blue.shade700),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Current Location:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _currentLocationAddress,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Destination Input
                  TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Destination Address',
                      hintText: 'e.g., 123 Patient St, Anytown',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.streetAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _getDirections(),
                  ),
                  const SizedBox(height: 16),

                  // Get Directions Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _getDirections,
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
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
                  const SizedBox(height: 24),

                  // Google Map Widget
                  Container(
                    height: 300, // Increased height for better map visibility
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: GoogleMap(
                      onMapCreated: _mapService.onMapCreated, // Pass controller to MapService
                      initialCameraPosition: _kInitialCameraPosition,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true, // Show user's current location dot
                      myLocationButtonEnabled: true, // Show button to recenter on user's location
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _navigationStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Note: Map data and routes are simulated for demonstration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
