import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class RealTimeMonitoringScreen extends StatefulWidget {
  const RealTimeMonitoringScreen({super.key});

  @override
  State<RealTimeMonitoringScreen> createState() => _RealTimeMonitoringScreenState();
}

class _RealTimeMonitoringScreenState extends State<RealTimeMonitoringScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, active, inactive, emergency

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Delhi coordinates
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusMarkers();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) {
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  void _loadBusMarkers() {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    final buses = busProvider.buses;

    _markers.clear();

    // Add current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Admin Location',
            snippet: 'Current position',
          ),
        ),
      );
    }

    // Add bus markers based on filter
    for (final bus in buses) {
      if (bus.hasLocation) {
        // Apply status filter
        if (_filterStatus != 'all') {
          if (_filterStatus == 'active' && !bus.isActive) continue;
          if (_filterStatus == 'inactive' && bus.isActive) continue;
          if (_filterStatus == 'emergency' && !bus.emergencyAlert) continue;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(bus.id),
            position: LatLng(bus.currentLatitude!, bus.currentLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              bus.emergencyAlert
                  ? BitmapDescriptor.hueRed
                  : bus.isActive
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'Bus ${bus.busNumber}',
              snippet: '${bus.routeDescription}\n'
                      'Status: ${bus.status}\n'
                      'Passengers: ${bus.passengerInfo}\n'
                      'Speed: ${bus.speed?.toStringAsFixed(1) ?? 'N/A'} km/h\n'
                      'Driver: ${bus.driverName}',
            ),
            onTap: () => _showBusDetails(bus),
          ),
        );
      }
    }

    setState(() {});
  }

  void _showBusDetails(BusModel bus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus ${bus.busNumber}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Route: ${bus.routeDescription}'),
            Text('Driver: ${bus.driverName} (${bus.driverPhone})'),
            Text('Status: ${bus.status.toUpperCase()}'),
            Text('Passengers: ${bus.passengerInfo}'),
            if (bus.speed != null) Text('Speed: ${bus.speed!.toStringAsFixed(1)} km/h'),
            Text('Fare: ₹${bus.busFare.toStringAsFixed(0)}'),
            if (bus.emergencyAlert) const Text('🚨 EMERGENCY ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _centerOnBus(bus);
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Center on Bus'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showBusAnalytics(bus);
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Analytics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBusAnalytics(BusModel bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics - Bus ${bus.busNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Efficiency: ${bus.speed != null ? 'Good' : 'N/A'}'),
            Text('Passenger Load: ${bus.currentPassengers != null ? '${((bus.currentPassengers! / bus.capacity) * 100).toStringAsFixed(0)}%' : 'N/A'}'),
            Text('Last Update: ${bus.lastUpdated != null ? _formatTimeAgo(bus.lastUpdated!) : 'Never'}'),
            if (bus.departureTime != null) Text('Next Departure: ${_formatTime(bus.departureTime!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _centerOnBus(BusModel bus) {
    if (bus.hasLocation && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(bus.currentLatitude!, bus.currentLongitude!),
          15.0,
        ),
      );
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  void _filterBuses(String status) {
    setState(() => _filterStatus = status);
    _loadBusMarkers();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Bus Monitoring'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _filterBuses,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Buses')),
              const PopupMenuItem(value: 'active', child: Text('Active Only')),
              const PopupMenuItem(value: 'inactive', child: Text('Inactive Only')),
              const PopupMenuItem(value: 'emergency', child: Text('Emergency Only')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_filterStatus.toUpperCase(), style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.filter_list),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBusMarkers();
              Provider.of<BusProvider>(context, listen: false).loadBuses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _defaultLocation,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _loadBusMarkers();
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onTap: (LatLng position) {
                    // Hide any open info windows
                    setState(() {});
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        onPressed: _centerOnCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _loadBusMarkers,
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Consumer<BusProvider>(
                        builder: (context, provider, _) {
                          final busesWithLocation = provider.busesWithLocation;
                          final emergencyBuses = provider.buses.where((bus) => bus.emergencyAlert).toList();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoChip(
                                icon: Icons.directions_bus,
                                label: 'Total',
                                value: provider.buses.length.toString(),
                                color: AppColors.primaryColor,
                              ),
                              _InfoChip(
                                icon: Icons.location_on,
                                label: 'Tracked',
                                value: busesWithLocation.length.toString(),
                                color: AppColors.secondaryColor,
                              ),
                              _InfoChip(
                                icon: Icons.warning,
                                label: 'Alerts',
                                value: emergencyBuses.length.toString(),
                                color: AppColors.error,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}