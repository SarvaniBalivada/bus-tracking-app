import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/auth_provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:bus_tracking_app/screens/admin/bus_management_screen.dart';
import 'package:bus_tracking_app/screens/admin/real_time_monitoring_screen.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const BusManagementScreen(),
    const RealTimeMonitoringScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final busProvider = Provider.of<BusProvider>(context, listen: false);
        await Future.wait([
          busProvider.loadBuses(),
          busProvider.loadStations(),
          busProvider.loadRoutes()
        ]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load data: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboard),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    auth.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(auth.user?.name ?? 'Admin'),
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Buses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor),
            label: 'Monitor',
          ),
        ],
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _showTriggerEmergencyDialog(BuildContext context, BusProvider busProvider) {
    BusModel? selectedBus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Trigger Emergency Alert'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a bus to trigger emergency alert:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BusModel?>(
                  value: selectedBus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Select Bus',
                  ),
                  items: busProvider.buses.map((bus) {
                    return DropdownMenuItem<BusModel>(
                      value: bus,
                      child: Text(
                        '${bus.busNumber} - ${bus.driverName} (${busProvider.getStationName(bus.fromStationId ?? '')} → ${busProvider.getStationName(bus.toStationId ?? '')})',
                      ),
                    );
                  }).toList(),
                  onChanged: (BusModel? bus) {
                    setState(() => selectedBus = bus);
                  },
                ),
                if (selectedBus != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus: ${selectedBus!.busNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Driver: ${selectedBus!.driverName}'),
                        Text('Phone: ${selectedBus!.driverPhone}'),
                        Text('Route: ${busProvider.getStationName(selectedBus!.fromStationId ?? '')} → ${busProvider.getStationName(selectedBus!.toStationId ?? '')}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBus == null
                  ? null
                  : () async {
                      // Trigger emergency alert
                      final success = await busProvider.updateBus(
                        selectedBus!.copyWith(
                          emergencyAlert: true,
                          status: 'emergency',
                          speed: 0.0, // Stop the bus
                        ),
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Emergency alert triggered for Bus ${selectedBus!.busNumber}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        Navigator.pop(context); // Close trigger dialog
                        if (context.mounted) {
                          Navigator.pop(context); // Close emergency alerts dialog
                          _showEmergencyAlertsDialog(context, busProvider); // Reopen to show new alert
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Trigger Alert'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyAlertsDialog(BuildContext context, BusProvider busProvider) {
    final emergencyBuses = busProvider.buses.where((bus) => bus.emergencyAlert).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alerts Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Emergency Alerts: ${emergencyBuses.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: emergencyBuses.isEmpty
                    ? const Center(
                        child: Text(
                          'No active emergency alerts',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: emergencyBuses.length,
                        itemBuilder: (context, index) {
                          final bus = emergencyBuses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.red.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.warning, color: Colors.red),
                              title: Text(
                                'Bus ${bus.busNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Driver: ${bus.driverName}\n'
                                'Phone: ${bus.driverPhone}\n'
                                'Location: ${bus.currentLatitude?.toStringAsFixed(4)}, '
                                '${bus.currentLongitude?.toStringAsFixed(4)}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  // Clear emergency alert
                                  final success = await busProvider.updateBus(
                                    bus.copyWith(emergencyAlert: false, status: 'active'),
                                  );
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Emergency alert cleared for Bus ${bus.busNumber}'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                    _showEmergencyAlertsDialog(context, busProvider);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear Alert'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showTriggerEmergencyDialog(context, busProvider),
            icon: const Icon(Icons.warning),
            label: const Text('Trigger Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusProvider>(
      builder: (context, busProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _StatCard(
                      title: 'Total Buses',
                      value: busProvider.buses.length.toString(),
                      icon: Icons.directions_bus,
                      color: AppColors.primaryColor,
                    ),
                    _StatCard(
                      title: 'Active Buses',
                      value: busProvider.activeBuses.length.toString(),
                      icon: Icons.directions_bus_filled,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      title: 'Total Stations',
                      value: busProvider.stations.length.toString(),
                      icon: Icons.location_on,
                      color: AppColors.warning,
                    ),
                    _StatCard(
                      title: 'Emergency Alerts',
                      value: busProvider.buses
                          .where((bus) => bus.emergencyAlert)
                          .length
                          .toString(),
                      icon: Icons.warning,
                      color: AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _ActionCard(
                      title: 'Add New Bus',
                      icon: Icons.add_circle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BusManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      title: 'Monitor Buses',
                      icon: Icons.monitor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RealTimeMonitoringScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      title: 'Emergency Alerts',
                      icon: Icons.warning_amber,
                      onTap: () => _showEmergencyAlertsDialog(context, busProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}