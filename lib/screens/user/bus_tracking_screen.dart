import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/screens/user/map_screen.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class BusTrackingScreen extends StatefulWidget {
  final String? fromStation;
  final String? toStation;

  const BusTrackingScreen({super.key, this.fromStation, this.toStation});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      await busProvider.loadBuses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching buses: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMap(String busId) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=bus+$busId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch map')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.userDashboard),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : busProvider.buses.isEmpty
              ? const Center(child: Text('No buses found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: busProvider.buses.length,
                  itemBuilder: (context, index) {
                    final bus = busProvider.buses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(bus.busNumber),
                        subtitle: Text(
                          'Status: ${bus.status} • ${bus.passengerInfo}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(busId: bus.id),
                              ),
                            );
                          },
                        ),
                        onTap: () => _launchMap(bus.id),
                      ),
                    );
                  },
                ),
    );
  }
}