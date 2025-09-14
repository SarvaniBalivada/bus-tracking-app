import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Analytics'),
        backgroundColor: AppColors.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buses', icon: Icon(Icons.directions_bus)),
            Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
            Tab(text: 'Alerts', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBusesTab(busProvider),
              _buildRevenueTab(busProvider),
              _buildAlertsTab(busProvider),
            ],
          );
        },
      ),
    );
  }


  Widget _buildBusesTab(BusProvider busProvider) {
    final buses = busProvider.buses;
    final activeBuses = busProvider.activeBuses;
    final inactiveBuses = buses.where((bus) => !bus.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bus Performance Report',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard('Active Buses', activeBuses.length, Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard('Inactive Buses', inactiveBuses.length, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Bus Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bus.isActive ? Colors.green : Colors.red,
                    child: const Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text('${bus.busNumber} - ${bus.driverName}'),
                  subtitle: Text(
                    'Route: ${busProvider.getStationName(bus.fromStationId ?? '')} → ${busProvider.getStationName(bus.toStationId ?? '')}\n'
                    'Capacity: ${bus.capacity}, Passengers: ${bus.currentPassengers ?? 0}\n'
                    'Status: ${bus.isActive ? 'Active' : 'Inactive'} • Fare: ₹${bus.busFare.toStringAsFixed(0)}',
                  ),
                  trailing: bus.hasLocation
                      ? const Icon(Icons.gps_fixed, color: Colors.green)
                      : const Icon(Icons.gps_off, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab(BusProvider busProvider) {
    final buses = busProvider.buses;
    final totalCapacity = buses.fold<int>(0, (sum, bus) => sum + bus.capacity);
    final totalPassengers = buses.fold<int>(0, (sum, bus) => sum + (bus.currentPassengers ?? 0));
    final totalRevenue = buses.fold<double>(0, (sum, bus) => sum + ((bus.currentPassengers ?? 0) * bus.busFare));
    final averageOccupancy = totalCapacity > 0 ? (totalPassengers / totalCapacity * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildRevenueCard(
                'Total Revenue',
                '₹${totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
              ),
              _buildRevenueCard(
                'Total Passengers',
                totalPassengers.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildRevenueCard(
                'Average Occupancy',
                '${averageOccupancy.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildRevenueCard(
                'Active Routes',
                busProvider.routes.length.toString(),
                Icons.route,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Revenue by Bus',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              final busRevenue = (bus.currentPassengers ?? 0) * bus.busFare;
              final occupancy = bus.capacity > 0 ? ((bus.currentPassengers ?? 0) / bus.capacity * 100) : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bus.isActive ? Colors.green : Colors.grey,
                    child: Text(
                      bus.busNumber.substring(bus.busNumber.length - 2),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('${bus.busNumber} - ${bus.driverName}'),
                  subtitle: Text(
                    'Revenue: ₹${busRevenue.toStringAsFixed(0)}\n'
                    'Passengers: ${bus.currentPassengers ?? 0}/${bus.capacity} (${occupancy.toStringAsFixed(1)}%)',
                  ),
                  trailing: Text(
                    '₹${bus.busFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(BusProvider busProvider) {
    final emergencyBuses = busProvider.buses.where((bus) => bus.emergencyAlert).toList();
    final activeBuses = busProvider.activeBuses;
    final inactiveBuses = busProvider.buses.where((bus) => !bus.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Alerts & System Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (emergencyBuses.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚨 Active Emergency Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: emergencyBuses.length,
                    itemBuilder: (context, index) {
                      final bus = emergencyBuses[index];
                      return ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text('${bus.busNumber} - ${bus.driverName}'),
                        subtitle: Text(
                          'Location: ${bus.currentLatitude?.toStringAsFixed(4)}, ${bus.currentLongitude?.toStringAsFixed(4)}\n'
                          'Phone: ${bus.driverPhone}',
                        ),
                        trailing: const Icon(Icons.call, color: Colors.blue),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
          const Text(
            'System Status Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard('Active Buses', activeBuses.length, Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard('Inactive Buses', inactiveBuses.length, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard('GPS Tracked', busProvider.busesWithLocation.length, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard('Emergency Alerts', emergencyBuses.length, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildRevenueCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}