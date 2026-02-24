import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carebridge/core/app_theme.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const MapSelectionScreen({super.key, this.initialLocation});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (_selectedLocation == null) {
      final position = await Geolocator.getCurrentPosition();
      _selectedLocation = LatLng(position.latitude, position.longitude);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_mapController != null && _selectedLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              child: const Text('Confirm',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandBlueGreen)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandBlueGreen))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ??
                        const LatLng(
                            20.5937, 78.9629), // Default to India center
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                      );
                    }
                  },
                  onTap: (latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                  },
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                          ),
                        },
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tap on the map to mark your service location',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        if (_selectedLocation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandBlueGreen),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
