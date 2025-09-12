import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/demo_auth_provider.dart';
import 'package:bus_tracking_app/providers/demo_bus_provider.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:bus_tracking_app/screens/admin/bus_management_screen.dart';
import 'package:bus_tracking_app/screens/admin/station_management_screen.dart';
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
    const StationManagementScreen(),
    const RealTimeMonitoringScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      final busProvider = Provider.of<DemoBusProvider>(context, listen: false);
      busProvider.loadBuses();
      busProvider.loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboard),
        actions: [
          Consumer<DemoAuthProvider>(
            builder: (context, auth, child) {
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
            icon: Icon(Icons.location_on),
            label: 'Stations',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.padding),
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
          Consumer<DemoBusProvider>(
            builder: (context, busProvider, child) {
              return GridView.count(
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
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
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
                  title: 'Add Station',
                  icon: Icons.add_location,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StationManagementScreen(),
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
                  title: 'View Reports',
                  icon: Icons.analytics,
                  onTap: () {
                    // TODO: Implement reports screen
                  },
                ),
              ],
            ),
          ),
        ],
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