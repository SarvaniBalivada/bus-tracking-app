import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/auth_provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:bus_tracking_app/screens/user/bus_tracking_screen.dart';
import 'package:bus_tracking_app/screens/user/bus_list_screen.dart';
import 'package:bus_tracking_app/screens/user/map_screen.dart';
import 'package:bus_tracking_app/screens/user/bus_route_search_screen.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const UserHomeScreen(),
    const BusListScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      busProvider.loadBuses();
      busProvider.loadStations();
      busProvider.loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.userDashboard),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    auth.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(auth.user?.name ?? 'User'),
                      subtitle: Text(auth.user?.email ?? ''),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onTap: () => auth.signOut(),
                    child: const ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sign Out'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Buses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  TextEditingController _fromController = TextEditingController();
  TextEditingController _toController = TextEditingController();
  String? _selectedFromStation;
  String? _selectedToStation;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _searchBuses() {
    final from = _selectedFromStation ?? _fromController.text.trim();
    final to = _selectedToStation ?? _toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both stations')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusRouteSearchScreen(),
        settings: RouteSettings(arguments: {'from': from, 'to': to}),
      ),
    ).then((value) {
      if (value is BusModel) {
        Provider.of<BusProvider>(context, listen: false).selectBus(value);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusTrackingScreen(
              fromStation: from,
              toStation: to,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryColor,
                          child: Text(
                            auth.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${auth.user?.name ?? 'User'}!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Track your buses in real-time',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Search Route Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: Colors.blue.shade600, size: 36),
                        const SizedBox(width: 12),
                        Text(
                          'Search Bus Routes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<BusProvider>(
                      builder: (context, busProvider, child) {
                        // Get unique station names from bus routes
                        final Set<String> routeStations = {};

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

                        for (final bus in busProvider.buses) {
                          if (bus.fromStationId != null) {
                            final fromStation = busProvider.stations.firstWhere(
                              (s) => s.id == bus.fromStationId,
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
                            if (fromStation.name.isNotEmpty) {
                              routeStations.add(fromStation.name);
                            }
                          }
                          if (bus.toStationId != null) {
                            final toStation = busProvider.stations.firstWhere(
                              (s) => s.id == bus.toStationId,
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
                            if (toStation.name.isNotEmpty) {
                              routeStations.add(toStation.name);
                            }
                          }

                          // Add intermediate stations from route descriptions
                          final intermediateStations = _getIntermediateStationsList(bus.routeDescription);
                          for (final station in intermediateStations) {
                            if (station.isNotEmpty && station.trim().isNotEmpty) {
                              routeStations.add(station.trim());
                            }
                          }
                        }

                        // Create a key that changes when stations change to force rebuild
                        final stationKey = routeStations.length + routeStations.fold(0, (sum, name) => sum + name.hashCode);

                        return Autocomplete<String>(
                          key: ValueKey('to_$stationKey'),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final options = routeStations.toList()..sort();

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
                            _selectedFromStation = selection;
                            _fromController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            return TextField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: InputDecoration(
                                labelText: 'From Station*',
                                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blue.shade600),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<BusProvider>(
                      builder: (context, busProvider, child) {
                        // Get unique station names from bus routes
                        final Set<String> routeStations = {};

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

                        for (final bus in busProvider.buses) {
                          if (bus.fromStationId != null) {
                            final fromStation = busProvider.stations.firstWhere(
                              (s) => s.id == bus.fromStationId,
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
                            if (fromStation.name.isNotEmpty) {
                              routeStations.add(fromStation.name);
                            }
                          }
                          if (bus.toStationId != null) {
                            final toStation = busProvider.stations.firstWhere(
                              (s) => s.id == bus.toStationId,
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
                            if (toStation.name.isNotEmpty) {
                              routeStations.add(toStation.name);
                            }
                          }

                          // Add intermediate stations from route descriptions
                          final intermediateStations = _getIntermediateStationsList(bus.routeDescription);
                          for (final station in intermediateStations) {
                            if (station.isNotEmpty && station.trim().isNotEmpty) {
                              routeStations.add(station.trim());
                            }
                          }
                        }

                        // Create a key that changes when stations change to force rebuild
                        final stationKey = routeStations.length + routeStations.fold(0, (sum, name) => sum + name.hashCode);

                        return Autocomplete<String>(
                          key: ValueKey(stationKey),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final options = routeStations.toList()..sort();

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
                            _selectedToStation = selection;
                            _toController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            return TextField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: InputDecoration(
                                labelText: 'To Station*',
                                prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _searchBuses,
                            icon: const Icon(Icons.search, size: 24),
                            label: const Text('Search', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _fromController.clear();
                              _toController.clear();
                              setState(() {
                                _selectedFromStation = null;
                                _selectedToStation = null;
                              });
                            },
                            icon: Icon(Icons.clear, color: Colors.blue.shade600, size: 24),
                            label: Text('Clear', style: TextStyle(fontSize: 18, color: Colors.blue.shade600)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quick Stats
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Consumer<BusProvider>(
              builder: (context, busProvider, _) {
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusListScreen(initialFilter: 'active'),
                            ),
                          );
                        },
                        child: _StatCard(
                          title: 'Active Buses',
                          value: busProvider.activeBuses.length.toString(),
                          icon: Icons.directions_bus,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Stations',
                        value: busProvider.stations.length.toString(),
                        icon: Icons.location_on,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Active Buses List
            Consumer<BusProvider>(
              builder: (context, busProvider, _) {
                final buses = busProvider.activeBuses;
                if (buses.isEmpty) {
                  return const Text('No active buses available');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Buses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...buses.map((bus) {
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
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus, size: 32),
                          title: Text('${fromStation.name} → ${toStation.name}', style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                            'Bus: ${bus.busNumber} • Seats: ${bus.capacity - (bus.currentPassengers ?? 0)} available • Fare: ₹${bus.busFare.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            bus.status.toUpperCase(),
                            style: TextStyle(fontSize: 12, color: bus.isActive ? AppColors.success : AppColors.warning),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BusListScreen(initialFilter: 'active'),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.cardElevation + 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
