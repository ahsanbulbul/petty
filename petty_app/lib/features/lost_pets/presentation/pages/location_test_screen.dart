import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:petty_app/core/services/location_service.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  String? _error;

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _error = null;
      });
      
      final location = await _locationService.getCurrentLocation();
      
      setState(() {
        _currentLocation = location;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentLocation != null)
              Text(
                'Location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Get Current Location'),
            ),
          ],
        ),
      ),
    );
  }
}