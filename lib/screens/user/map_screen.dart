import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:omnitrack/providers/bus_provider.dart';
import 'package:omnitrack/models/bus_model.dart';
import 'package:omnitrack/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  final String? busId;

  const MapScreen({super.key, this.busId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = false;
  Position? _currentPosition;

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Delhi coordinates
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
      await _fetchBusLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _fetchBusLocation() async {
    if (widget.busId == null) return;

    try {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      final bus = busProvider.buses.firstWhere(
        (bus) => bus.id == widget.busId,
        orElse: () => BusModel(
          id: '',
          busNumber: '',
          driverName: '',
          driverPhone: '',
          capacity: 0,
          status: BusStatus.inactive,
          routeId: '',
          deviceId: '',
          busFare: 0.0,
          routeDescription: '',
          fromStationId: '',
          toStationId: '',
          emergencyAlert: false,
          currentLatitude: null,
          currentLongitude: null,
        ),
      );

      if (bus.hasLocation) {
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(widget.busId!),
              position: LatLng(bus.currentLatitude!, bus.currentLongitude!),
              infoWindow: InfoWindow(title: bus.busNumber),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                bus.emergencyAlert ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
              ),
            ),
          );
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(bus.currentLatitude!, bus.currentLongitude!)),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bus location: $e')),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _defaultLocation,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        ),
                      );
                    }
                  },
                ),
                if (_isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}