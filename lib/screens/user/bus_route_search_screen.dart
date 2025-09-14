import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:bus_tracking_app/screens/user/bus_list_screen.dart';

class BusRouteSearchScreen extends StatefulWidget {
  const BusRouteSearchScreen({super.key});

  @override
  _BusRouteSearchScreenState createState() => _BusRouteSearchScreenState();
}

class _BusRouteSearchScreenState extends State<BusRouteSearchScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  List<BusModel> searchResults = [];
  String? initialFrom;
  String? initialTo;
  Set<String> allStations = {}; // Store stations as state

  // Helper method to parse intermediate stations from route description
  List<String> _getIntermediateStationsList(String routeDesc) {
    // Clean the route description first
    String cleanDesc = routeDesc.trim();

    // Handle multiple separator formats
    List<String> separators = ['->', '→', '↔', ',', ';', '|'];

    for (String separator in separators) {
      if (cleanDesc.contains(separator)) {
        final parts = cleanDesc.split(separator).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        // Remove any empty or whitespace-only parts
        final filtered = parts.where((part) {
          String trimmed = part.trim();
          return trimmed.isNotEmpty && !RegExp(r'^\s*$').hasMatch(trimmed);
        }).toList();

        return filtered;
      }
    }

    // If no separators found, try to extract station-like words
    final words = cleanDesc.split(RegExp(r'\s+')).where((word) => word.length > 2).toList();
    return words;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        initialFrom = args['from'];
        initialTo = args['to'];
        fromController.text = initialFrom ?? '';
        toController.text = initialTo ?? '';
        if (initialFrom != null && initialTo != null) {
          searchBuses();
        }
      }
      // Populate stations after widget is built
      _updateStations();
    });
  }

  void _updateStations() {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    allStations.clear();

    // Add from/to stations from database
    for (final bus in busProvider.buses) {
      if (bus.fromStationId != null) {
        final fromStation = busProvider.stations.firstWhere(
          (s) => s.id == bus.fromStationId,
          orElse: () => StationModel(id: '', name: bus.fromStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
        );
        if (fromStation.name.isNotEmpty) {
          allStations.add(fromStation.name);
        }
      }
      if (bus.toStationId != null) {
        final toStation = busProvider.stations.firstWhere(
          (s) => s.id == bus.toStationId,
          orElse: () => StationModel(id: '', name: bus.toStationId ?? '', address: '', latitude: 0, longitude: 0, routeIds: [], createdAt: DateTime.now()),
        );
        if (toStation.name.isNotEmpty) {
          allStations.add(toStation.name);
        }
      }
    }

    // Add intermediate stations from route descriptions
    for (final bus in busProvider.buses) {
      final intermediateStations = _getIntermediateStationsList(bus.routeDescription);
      for (final station in intermediateStations) {
        if (station.isNotEmpty && station.trim().isNotEmpty) {
          allStations.add(station.trim());
        }
      }
    }

    setState(() {}); // Trigger rebuild to update autocomplete
  }

  void searchBuses() {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    String from = fromController.text.trim();
    String to = toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both from and to stations')),
      );
      return;
    }

    setState(() {
      searchResults = busProvider.buses.where((bus) {
        if (!bus.isActive) return false;

        // Get station names from bus
        final fromStation = busProvider.stations.firstWhere(
          (station) => station.id == bus.fromStationId,
          orElse: () => StationModel(
            id: '',
            name: bus.fromStationId ?? '',
            address: '',
            latitude: 0,
            longitude: 0,
            routeIds: [],
            createdAt: DateTime.now(),
          ),
        );

        final toStation = busProvider.stations.firstWhere(
          (station) => station.id == bus.toStationId,
          orElse: () => StationModel(
            id: '',
            name: bus.toStationId ?? '',
            address: '',
            latitude: 0,
            longitude: 0,
            routeIds: [],
            createdAt: DateTime.now(),
          ),
        );

        // Get intermediate stations from route description
        final intermediateStations = _getIntermediateStationsList(bus.routeDescription);

        // Check if selected stations match from/to/intermediate stations (flexible matching)
        final fromMatch = fromStation.name.toLowerCase().contains(from.toLowerCase()) ||
            intermediateStations.any((station) => station.toLowerCase().contains(from.toLowerCase()));

        final toMatch = toStation.name.toLowerCase().contains(to.toLowerCase()) ||
            intermediateStations.any((station) => station.toLowerCase().contains(to.toLowerCase()));

        return fromMatch && toMatch;
      }).toList();
    });
  }

  void clearSearch() {
    fromController.clear();
    toController.clear();
    setState(() {
      searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusProvider>(
      builder: (context, busProvider, child) {
        // Update stations when bus data changes
        if (allStations.isEmpty || busProvider.buses.length > allStations.length - 4) { // -4 for main stations
          _updateStations();
        }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Bus Routes"),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // From station
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final options = allStations.toList()..sort();

                if (textEditingValue.text.isEmpty) {
                  // Show first 10 stations when empty
                  return options.take(10).toList();
                }

                // More flexible matching
                final query = textEditingValue.text.toLowerCase().trim();
                final matches = options.where((station) {
                  final stationLower = station.toLowerCase();
                  // Match start of word, anywhere in station name, or abbreviation
                  return stationLower.startsWith(query) ||
                         stationLower.contains(query) ||
                         query.length >= 2 && stationLower.contains(query);
                }).toList();

                return matches.take(10).toList(); // Limit to 10 suggestions
              },
              onSelected: (String selection) {
                fromController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                // Sync with our controller
                if (fromController.text != fieldTextEditingController.text) {
                  fieldTextEditingController.text = fromController.text;
                }
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: "From Station",
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    suffixIcon: fieldTextEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              fieldTextEditingController.clear();
                              fromController.clear();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    fromController.text = value;
                  },
                );
              },
            ),
            SizedBox(height: 10),

            // To station
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final options = allStations.toList()..sort();

                if (textEditingValue.text.isEmpty) {
                  // Show first 10 stations when empty
                  return options.take(10).toList();
                }

                // More flexible matching
                final query = textEditingValue.text.toLowerCase().trim();
                final matches = options.where((station) {
                  final stationLower = station.toLowerCase();
                  // Match start of word, anywhere in station name, or abbreviation
                  return stationLower.startsWith(query) ||
                         stationLower.contains(query) ||
                         query.length >= 2 && stationLower.contains(query);
                }).toList();

                return matches.take(10).toList(); // Limit to 10 suggestions
              },
              onSelected: (String selection) {
                toController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                // Sync with our controller
                if (toController.text != fieldTextEditingController.text) {
                  fieldTextEditingController.text = toController.text;
                }
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: "To Station",
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    suffixIcon: fieldTextEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              fieldTextEditingController.text = '';
                              toController.clear();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    toController.text = value;
                  },
                );
              },
            ),
            SizedBox(height: 20),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: searchBuses,
                  icon: Icon(Icons.search),
                  label: Text("Search"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: Size(120, 40),
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: clearSearch,
                  icon: Icon(Icons.clear),
                  label: Text("Clear"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(120, 40),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Search results
            Expanded(
              child: searchResults.isEmpty
                  ? Center(child: Text("No buses found"))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final bus = searchResults[index];
                        final busProvider = Provider.of<BusProvider>(context, listen: false);

                        // Get station names
                        final fromStation = busProvider.stations.firstWhere(
                          (station) => station.id == bus.fromStationId,
                          orElse: () => StationModel(
                            id: '',
                            name: bus.fromStationId ?? 'Unknown',
                            address: '',
                            latitude: 0,
                            longitude: 0,
                            routeIds: [],
                            createdAt: DateTime.now(),
                          ),
                        );

                        final toStation = busProvider.stations.firstWhere(
                          (station) => station.id == bus.toStationId,
                          orElse: () => StationModel(
                            id: '',
                            name: bus.toStationId ?? 'Unknown',
                            address: '',
                            latitude: 0,
                            longitude: 0,
                            routeIds: [],
                            createdAt: DateTime.now(),
                          ),
                        );

                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.directions_bus),
                            title: Text("${fromStation.name} → ${toStation.name}"),
                            subtitle: Text(
                                "Bus: ${bus.busNumber} • Seats: ${bus.capacity - (bus.currentPassengers ?? 0)} available • Fare: ₹${bus.busFare.toStringAsFixed(0)}"),
                            trailing: Text(
                              "ACTIVE",
                              style: TextStyle(color: Colors.green),
                            ),
                            onTap: () {
                              // Navigate to detailed bus view with route visualization
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusListScreenResults(buses: [bus]),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}