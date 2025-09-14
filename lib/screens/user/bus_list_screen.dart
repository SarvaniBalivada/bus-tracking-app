import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/screens/user/map_screen.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class BusListScreen extends StatefulWidget {
  final String initialFilter;
  final List<BusModel>? buses; // Optional filtered buses list

  const BusListScreen({super.key, this.initialFilter = 'all', this.buses});

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class BusListScreenResults extends StatelessWidget {
  final List<BusModel> buses;

  const BusListScreenResults({Key? key, required this.buses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    // Ensure stations are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (busProvider.stations.isEmpty) {
        busProvider.loadStations(); // Load stations data
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Buses"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: buses.isEmpty
          ? const Center(child: Text("No buses found for this route."))
          : ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                final busProvider = Provider.of<BusProvider>(context, listen: false);

                // Get actual station names with fallback
                final fromStation = busProvider.stations.firstWhere(
                  (station) => station.id == bus.fromStationId || station.name.toLowerCase() == (bus.fromStationId ?? '').toLowerCase(),
                  orElse: () => StationModel(
                    id: '',
                    name: bus.fromStationId ?? 'Unknown',
                    address: '',
                    latitude: 0,
                    longitude: 0,
                    routeIds: [],
                    createdAt: DateTime.now(),
                  ),
                ).name;

                final toStation = busProvider.stations.firstWhere(
                  (station) => station.id == bus.toStationId || station.name.toLowerCase() == (bus.toStationId ?? '').toLowerCase(),
                  orElse: () => StationModel(
                    id: '',
                    name: bus.toStationId ?? 'Unknown',
                    address: '',
                    latitude: 0,
                    longitude: 0,
                    routeIds: [],
                    createdAt: DateTime.now(),
                  ),
                ).name;

                // Parse route description for intermediate stations
                final routeParts = _parseRouteDescription(bus.routeDescription);
                final intermediateStations = _getIntermediateStationsList(bus.routeDescription);

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bus Name and Status
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.directions_bus, color: AppColors.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bus.busNumber,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bus.isActive ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bus.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showBusDetails(context, bus);
                                },
                                icon: const Icon(Icons.info),
                                label: const Text("Details"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  busProvider.selectBus(bus);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => MapScreen(busId: bus.id)),
                                  );
                                },
                                icon: const Icon(Icons.map),
                                label: const Text("Track"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(),

                      // Route Timeline
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Route Timeline",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 300, // Fixed height for vertical scrolling
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildVerticalTimelineColumn(
                                    fromStation ?? 'Unknown',
                                    intermediateStations ?? [],
                                    toStation ?? 'Unknown',
                                    bus,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Map<String, String?> _parseRouteDescription(String routeDesc) {
    // Handle "from -> 1 -> 2 -> 3 -> to" format
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      if (parts.length >= 4) {
        final from = parts.first;
        final to = parts.last;
        String? via;
        if (parts.length > 4) {
          via = parts.sublist(1, parts.length - 1).join(' -> ');
        }
        return {'from': from, 'via': via, 'to': to};
      }
    }

    // First try comma-separated format (used in demo data)
    final commaParts = routeDesc.split(',').map((s) => s.trim()).toList();
    if (commaParts.length >= 2) {
      final from = commaParts.first;
      final to = commaParts.last;
      String? via;
      if (commaParts.length > 2) {
        via = commaParts.sublist(1, commaParts.length - 1).join(', ');
      }
      return {'from': from, 'via': via, 'to': to};
    }

    // Fallback to ↔ separator
    final arrowParts = routeDesc.split('↔').map((s) => s.trim()).toList();
    if (arrowParts.length >= 2) {
      final from = arrowParts.first;
      final to = arrowParts.last;
      String? via;
      if (arrowParts.length > 2) {
        via = arrowParts.sublist(1, arrowParts.length - 1).join(', ');
      }
      return {'from': from, 'via': via, 'to': to};
    }

    return {'from': routeDesc, 'via': null, 'to': null};
  }


  void _showBusDetails(BuildContext context, BusModel bus) {
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    // Get station names with fallback
    final fromStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.fromStationId,
      orElse: () => StationModel(
        id: '',
        name: bus.fromStationId ?? 'Unknown Station',
        address: '',
        latitude: 0,
        longitude: 0,
        routeIds: [],
        createdAt: DateTime.now(),
      ),
    ).name;

    final toStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.toStationId,
      orElse: () => StationModel(
        id: '',
        name: bus.toStationId ?? 'Unknown Station',
        address: '',
        latitude: 0,
        longitude: 0,
        routeIds: [],
        createdAt: DateTime.now(),
      ),
    ).name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bus ${bus.busNumber} Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Bus Number', bus.busNumber),
              _buildDetailRow('From Station', fromStation.isNotEmpty ? fromStation : 'Unknown'),
              _buildDetailRow('To Station', toStation.isNotEmpty ? toStation : 'Unknown'),
              _buildDetailRow('Fare', '₹${bus.busFare.toStringAsFixed(0)}'),
              _buildDetailRow('Capacity', '${bus.capacity} seats'),
              _buildDetailRow('Available Seats', '${bus.capacity - (bus.currentPassengers ?? 0)}'),
              _buildDetailRow('Status', bus.isActive ? 'Active' : 'Inactive'),
              if (bus.hasLocation) ...[
                _buildDetailRow('Current Speed', '${bus.speed?.toStringAsFixed(1)} km/h'),
                _buildDetailRow('Last Updated', _formatAgo(bus.lastUpdated)),
              ],
              if (bus.departureTime != null)
                _buildDetailRow('Departure Time', _formatTime(bus.departureTime!)),
              if (bus.arrivalTime != null)
                _buildDetailRow('Arrival Time', _formatTime(bus.arrivalTime!)),
              _buildDetailRow('Route Description', bus.routeDescription),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  String _formatAgo(DateTime? dt) {
    if (dt == null) return 'n/a';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  double _calculateTimelineHeight(int intermediateCount) {
    if (intermediateCount == 0) return 120;
    if (intermediateCount == 1) return 160;
    if (intermediateCount == 2) return 200;
    if (intermediateCount == 3) return 240;
    return 120 + (intermediateCount * 40.0);
  }

  double _calculateTimelineWidth(int intermediateCount) {
    double baseWidth = 400; // From and To stations
    double intermediateWidth = intermediateCount * 150.0;
    return baseWidth + intermediateWidth + 50;
  }

  List<Widget> _buildTimelineEntriesFlexible(String fromStation, List<String> intermediateStations, String toStation) {
    List<Widget> entries = [];
    final intermediateCount = intermediateStations.length;
    final totalHeight = _calculateTimelineHeight(intermediateCount);
    final spacing = intermediateCount > 0 ? (totalHeight - 80.0) / (intermediateCount + 1) : 60.0;

    // From Station (Green)
    entries.add(Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fromStation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    ));

    // Intermediate Stations (Grey circles for visibility)
    for (int i = 0; i < intermediateCount; i++) {
      final station = intermediateStations[i];
      final topPosition = 40.0 + ((i + 1) * spacing); // Start after from station with spacing
      entries.add(Positioned(
        top: topPosition,
        left: 0,
        right: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18, // Slightly larger for visibility
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.grey, // Changed from white to grey for contrast
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Colors.black12, width: 1)), // Subtle border
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                station,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    // To Station (Red)
    entries.add(Positioned(
      top: totalHeight - 40,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              toStation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    ));

    return entries;
  }



  static List<String> _getIntermediateStationsList(String routeDesc) {
    // Handle intermediate stations format like "Bhimavaram -> Vizag -> Tekkali"
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      // Return all parts as intermediate stations - the from/to come from database
      return parts.where((part) => part.isNotEmpty).toList();
    }

    // First try comma-separated format (used in demo data)
    final commaParts = routeDesc.split(',').map((s) => s.trim()).toList();
    if (commaParts.length > 0) {
      return commaParts.where((part) => part.isNotEmpty).toList();
    }

    // Fallback to ↔ separator
    final arrowParts = routeDesc.split('↔').map((s) => s.trim()).toList();
    if (arrowParts.length > 0) {
      final intermediatePart = arrowParts.join(', ');
      return intermediatePart.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return [];
  }

  static Widget _buildVerticalTimelineColumn(String fromStation, List<String> intermediateStations, String toStation, BusModel bus) {
    final List<Widget> timelineItems = [];

    // 1. Add FROM station (Starting Point - Green)
    timelineItems.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40, // Fixed width for alignment
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: const Icon(Icons.trip_origin, color: Colors.white, size: 14),
                ),
                // Add connecting line if there are intermediate stations or destination
                if (intermediateStations.isNotEmpty || toStation.isNotEmpty)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromStation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Starting Point',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );

    // 2. Add INTERMEDIATE stations (Orange)
    for (int i = 0; i < intermediateStations.length; i++) {
      final stopNumber = intermediateStations[i];
      final isLastIntermediate = i == intermediateStations.length - 1;

      timelineItems.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40, // Fixed width for alignment
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: Text(
                      stopNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Add connecting line if not the last intermediate or if there's a destination
                  if (!isLastIntermediate || toStation.isNotEmpty)
                    Container(
                      width: 2,
                      height: 50,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Stop ${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Add TO station (Final Destination - Red)
    if (toStation.isNotEmpty) {
      timelineItems.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40, // Fixed width for alignment
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toStation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text(
                    'Final Destination',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timelineItems,
    );
  }

}

class _BusListScreenState extends State<BusListScreen> {
  late String _filter;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String? _selectedFromStation;
  String? _selectedToStation;


  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      if (busProvider.buses.isEmpty) busProvider.loadBuses();
      if (busProvider.stations.isEmpty) busProvider.loadStations();
      if (busProvider.routes.isEmpty) busProvider.loadRoutes();
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusProvider>(
      builder: (context, busProvider, child) {
        final Set<String> routeStations = {};

        // Add from/to stations from database
        for (final bus in busProvider.buses) {
          if (bus.fromStationId != null) {
            final fromStation = busProvider.stations.firstWhere(
              (s) => s.id == bus.fromStationId,
              orElse: () => StationModel(id: '', name: bus.fromStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
            );
            if (fromStation.name.isNotEmpty) routeStations.add(fromStation.name);
          }
          if (bus.toStationId != null) {
            final toStation = busProvider.stations.firstWhere(
              (s) => s.id == bus.toStationId,
              orElse: () => StationModel(id: '', name: bus.toStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
            );
            if (toStation.name.isNotEmpty) routeStations.add(toStation.name);
          }
        }

        // Add intermediate stations from route descriptions
        for (final bus in busProvider.buses) {
          final intermediateStations = _getIntermediateStationsList(bus.routeDescription);
          for (final station in intermediateStations) {
            if (station.isNotEmpty) routeStations.add(station);
          }
        }

        List<BusModel> buses = widget.buses ?? busProvider.buses;
        if (widget.buses == null && _filter == 'active') {
          buses = buses.where((bus) => bus.isActive).toList();
        }
        if (_selectedFromStation != null || _selectedToStation != null) {
          buses = buses.where((bus) {
            // Get from and to stations from database
            final fromStation = busProvider.stations.firstWhere(
              (s) => s.id == bus.fromStationId,
              orElse: () => StationModel(id: '', name: bus.fromStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
            );
            final toStation = busProvider.stations.firstWhere(
              (s) => s.id == bus.toStationId,
              orElse: () => StationModel(id: '', name: bus.toStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
            );

            // Get intermediate stations from route description
            final intermediateStations = _getIntermediateStationsList(bus.routeDescription);

            // Check if selected stations match from/to/intermediate stations (partial match)
            bool fromMatch = _selectedFromStation == null ||
                fromStation.name.toLowerCase().contains(_selectedFromStation!.toLowerCase()) ||
                intermediateStations.any((station) => station.toLowerCase().contains(_selectedFromStation!.toLowerCase()));

            bool toMatch = _selectedToStation == null ||
                toStation.name.toLowerCase().contains(_selectedToStation!.toLowerCase()) ||
                intermediateStations.any((station) => station.toLowerCase().contains(_selectedToStation!.toLowerCase()));

            return fromMatch && toMatch;
          }).toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bus List'),
            backgroundColor: AppColors.primaryColor,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _filter = value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Buses')),
                  const PopupMenuItem(value: 'active', child: Text('Active Only')),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(_filter == 'all' ? 'ALL' : 'ACTIVE', style: const TextStyle(fontSize: 12)),
                      const Icon(Icons.filter_list),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final options = routeStations.toList()..sort();
                              if (textEditingValue.text.isEmpty) return options;
                              return options.where((stationName) => stationName.toLowerCase().contains(textEditingValue.text.toLowerCase())).toList();
                            },
                            onSelected: (String selection) {
                              setState(() {
                                _selectedFromStation = selection;
                                _fromController.text = selection;
                              });
                            },
                            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                              if (_selectedFromStation != null && _fromController.text != _selectedFromStation) _fromController.text = _selectedFromStation!;
                              return TextField(
                                controller: _fromController,
                                focusNode: fieldFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'From Station',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _selectedFromStation != null
                                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                                          setState(() {
                                            _selectedFromStation = null;
                                            _fromController.clear();
                                          });
                                        })
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isEmpty) _selectedFromStation = null;
                                    else _selectedFromStation = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final options = routeStations.toList()..sort();
                              if (textEditingValue.text.isEmpty) return options;
                              return options.where((stationName) => stationName.toLowerCase().contains(textEditingValue.text.toLowerCase())).toList();
                            },
                            onSelected: (String selection) {
                              setState(() {
                                _selectedToStation = selection;
                                _toController.text = selection;
                              });
                            },
                            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                              if (_selectedToStation != null && _toController.text != _selectedToStation) _toController.text = _selectedToStation!;
                              return TextField(
                                controller: _toController,
                                focusNode: fieldFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'To Station',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _selectedToStation != null
                                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                                          setState(() {
                                            _selectedToStation = null;
                                            _toController.clear();
                                          });
                                        })
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isEmpty) _selectedToStation = null;
                                    else _selectedToStation = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFromStation != null || _selectedToStation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Showing buses from ${_selectedFromStation ?? 'any station'} to ${_selectedToStation ?? 'any station'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => Future(() async {
                    final busProvider = Provider.of<BusProvider>(context, listen: false);
                    await busProvider.loadBuses();
                    await busProvider.loadStations();
                    await busProvider.loadRoutes();
                  }),
                  child: buses.isEmpty
                      ? const Center(child: Text('No buses found matching the criteria'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: buses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final bus = buses[index];
                            return _BusTile(bus: bus);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getIntermediateStationsList(String routeDesc) {
    // Handle intermediate stations format like "Bhimavaram -> Vizag -> Tekkali"
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      // Return all parts as intermediate stations - the from/to come from database
      return parts.where((part) => part.isNotEmpty).toList();
    }

    // First try comma-separated format (used in demo data)
    final commaParts = routeDesc.split(',').map((s) => s.trim()).toList();
    if (commaParts.length > 0) {
      return commaParts.where((part) => part.isNotEmpty).toList();
    }

    // Fallback to ↔ separator
    final arrowParts = routeDesc.split('↔').map((s) => s.trim()).toList();
    if (arrowParts.length > 0) {
      final intermediatePart = arrowParts.join(', ');
      return intermediatePart.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return [];
  }
}

class _BusTile extends StatelessWidget {
  final BusModel bus;

  const _BusTile({required this.bus});

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    final fromStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.fromStationId,
      orElse: () => StationModel(id: '', name: bus.fromStationId ?? 'Unknown', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
    );
    final toStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.toStationId,
      orElse: () => StationModel(id: '', name: bus.toStationId ?? 'Unknown', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
    );

    // Parse route description for intermediate stations
    final routeParts = _parseRouteDescription(bus.routeDescription);
    final intermediateStations = _getIntermediateStationsList(bus.routeDescription);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bus Header with From/To
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${fromStation.name} To: ${toStation.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bus.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bus Details Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.attach_money,
                    '₹${bus.busFare.toStringAsFixed(0)}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    Icons.event_seat,
                    '${bus.capacity - (bus.currentPassengers ?? 0)}/${bus.capacity}',
                    Colors.blue,
                  ),
                ),
                if (bus.hasLocation)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.speed,
                      '${bus.speed?.toStringAsFixed(1)} km/h',
                      Colors.orange,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBusDetails(context, bus),
                    icon: const Icon(Icons.info, size: 18),
                    label: const Text("Details"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      busProvider.selectBus(bus);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MapScreen(busId: bus.id)),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text("Track"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRouteTimelineDialog(context, bus),
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text("Timeline"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }











  static Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static void _showRouteTimelineDialog(BuildContext context, BusModel bus) {
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    final fromStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.fromStationId,
      orElse: () => StationModel(id: '', name: bus.fromStationId ?? 'Unknown', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
    ).name;

    final toStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.toStationId,
      orElse: () => StationModel(id: '', name: bus.toStationId ?? 'Unknown', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
    ).name;

    final intermediateStations = _getIntermediateStationsList(bus.routeDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${bus.busNumber} Route Timeline'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildVerticalTimelineColumn(fromStation, intermediateStations, toStation, bus),
            ),
          ),
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

  static Map<String, String?> _parseRouteDescription(String routeDesc) {
    // Handle "from -> 1 -> 2 -> 3 -> to" format
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      if (parts.length >= 4) {
        final from = parts.first;
        final to = parts.last;
        String? via;
        if (parts.length > 4) {
          via = parts.sublist(1, parts.length - 1).join(' -> ');
        }
        return {'from': from, 'via': via, 'to': to};
      }
    }

    // First try comma-separated format (used in demo data)
    final commaParts = routeDesc.split(',').map((s) => s.trim()).toList();
    if (commaParts.length >= 2) {
      final from = commaParts.first;
      final to = commaParts.last;
      String? via;
      if (commaParts.length > 2) {
        via = commaParts.sublist(1, commaParts.length - 1).join(', ');
      }
      return {'from': from, 'via': via, 'to': to};
    }

    // Fallback to ↔ separator
    final arrowParts = routeDesc.split('↔').map((s) => s.trim()).toList();
    if (arrowParts.length >= 2) {
      final from = arrowParts.first;
      final to = arrowParts.last;
      String? via;
      if (arrowParts.length > 2) {
        via = arrowParts.sublist(1, arrowParts.length - 1).join(', ');
      }
      return {'from': from, 'via': via, 'to': to};
    }

    return {'from': routeDesc, 'via': null, 'to': null};
  }

  static List<String> _getIntermediateStationsList(String routeDesc) {
    // Handle intermediate stations format like "Bhimavaram -> Vizag -> Tekkali"
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      // Return all parts as intermediate stations - the from/to come from database
      return parts.where((part) => part.isNotEmpty).toList();
    }

    // First try comma-separated format (used in demo data)
    final commaParts = routeDesc.split(',').map((s) => s.trim()).toList();
    if (commaParts.length > 0) {
      return commaParts.where((part) => part.isNotEmpty).toList();
    }

    // Fallback to ↔ separator
    final arrowParts = routeDesc.split('↔').map((s) => s.trim()).toList();
    if (arrowParts.length > 0) {
      final intermediatePart = arrowParts.join(', ');
      return intermediatePart.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return [];
  }

  static void _showBusDetails(BuildContext context, BusModel bus) {
    final busProvider = Provider.of<BusProvider>(context, listen: false);

    // Get station names with fallback
    final fromStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.fromStationId,
      orElse: () => StationModel(
        id: '',
        name: bus.fromStationId ?? 'Unknown Station',
        address: '',
        latitude: 0,
        longitude: 0,
        routeIds: [],
        createdAt: DateTime.now(),
      ),
    ).name;

    final toStation = busProvider.stations.firstWhere(
      (station) => station.id == bus.toStationId,
      orElse: () => StationModel(
        id: '',
        name: bus.toStationId ?? 'Unknown Station',
        address: '',
        latitude: 0,
        longitude: 0,
        routeIds: [],
        createdAt: DateTime.now(),
      ),
    ).name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bus ${bus.busNumber} Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Bus Number', bus.busNumber),
              _buildDetailRow('From Station', fromStation.isNotEmpty ? fromStation : 'Unknown'),
              _buildDetailRow('To Station', toStation.isNotEmpty ? toStation : 'Unknown'),
              _buildDetailRow('Fare', '₹${bus.busFare.toStringAsFixed(0)}'),
              _buildDetailRow('Capacity', '${bus.capacity} seats'),
              _buildDetailRow('Available Seats', '${bus.capacity - (bus.currentPassengers ?? 0)}'),
              _buildDetailRow('Status', bus.isActive ? 'Active' : 'Inactive'),
              if (bus.hasLocation) ...[
                _buildDetailRow('Current Speed', '${bus.speed?.toStringAsFixed(1)} km/h'),
                _buildDetailRow('Last Updated', _formatAgo(bus.lastUpdated)),
              ],
              if (bus.departureTime != null)
                _buildDetailRow('Departure Time', _formatTime(bus.departureTime!)),
              if (bus.arrivalTime != null)
                _buildDetailRow('Arrival Time', _formatTime(bus.arrivalTime!)),
              _buildDetailRow('Route Description', bus.routeDescription),
            ],
          ),
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

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  static String _formatAgo(DateTime? dt) {
    if (dt == null) return 'n/a';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  static Widget _buildVerticalTimelineColumn(String fromStation, List<String> intermediateStations, String toStation, BusModel bus) {
    final List<Widget> timelineItems = [];

    // 1. Add FROM station (Starting Point - Green)
    timelineItems.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40, // Fixed width for alignment
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: const Icon(Icons.trip_origin, color: Colors.white, size: 14),
                ),
                // Add connecting line if there are intermediate stations or destination
                if (intermediateStations.isNotEmpty || toStation.isNotEmpty)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromStation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Starting Point',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );

    // 2. Add INTERMEDIATE stations (Orange)
    for (int i = 0; i < intermediateStations.length; i++) {
      final stopNumber = intermediateStations[i];
      final isLastIntermediate = i == intermediateStations.length - 1;

      timelineItems.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40, // Fixed width for alignment
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: Text(
                      stopNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Add connecting line if not the last intermediate or if there's a destination
                  if (!isLastIntermediate || toStation.isNotEmpty)
                    Container(
                      width: 2,
                      height: 50,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stopNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Stop ${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Add TO station (Final Destination - Red)
    if (toStation.isNotEmpty) {
      timelineItems.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40, // Fixed width for alignment
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toStation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text(
                    'Final Destination',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timelineItems,
    );
  }
}

class _MovingBusIcon extends StatefulWidget {
  final BusModel bus;
  final String fromStation;
  final String toStation;
  final Map<String, String?> routeParts;
  final int intermediateCount;

  const _MovingBusIcon({
    super.key,
    required this.bus,
    required this.fromStation,
    required this.toStation,
    required this.routeParts,
    required this.intermediateCount,
  });

  @override
  _MovingBusIconState createState() => _MovingBusIconState();
}

class _MovingBusIconState extends State<_MovingBusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    if (_controller.isAnimating) _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted || !_controller.isAnimating) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double progress = _calculateBusProgress();
        progress = progress.clamp(0.0, 1.0);
        double totalHeight = widget.intermediateCount > 0 ? 120 + (widget.intermediateCount * 60.0) : 200;
        double topPosition = 10 + (progress * (totalHeight - 20));
        topPosition = topPosition.clamp(10.0, totalHeight - 30);
        return Positioned(
          left: 2,
          top: topPosition,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 10),
          ),
        );
      },
    );
  }

  double _calculateBusProgress() {
    double totalHeight = widget.intermediateCount > 0 ? 120 + (widget.intermediateCount * 60.0) : 200;
    if (widget.bus.speed != null && widget.bus.speed! > 0) {
      double baseProgress = 0.3;
      double speedFactor = (widget.bus.speed! / 60.0).clamp(0.0, 0.4);
      double timeFactor = (DateTime.now().second % 10) / 10.0;
      return (baseProgress + speedFactor + timeFactor * 0.2).clamp(0.0, 1.0);
    }
    return 0.5;
  }
}