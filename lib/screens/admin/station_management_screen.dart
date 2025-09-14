import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';

class StationManagementScreen extends StatefulWidget {
  const StationManagementScreen({super.key});

  @override
  State<StationManagementScreen> createState() => _StationManagementScreenState();
}

class _StationManagementScreenState extends State<StationManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load stations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BusProvider>(context, listen: false);
      provider.loadStations();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<BusProvider>(context, listen: false);
    final station = StationModel(
      id: '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: double.parse(_latController.text),
      longitude: double.parse(_lngController.text),
      routeIds: const [],
      createdAt: DateTime.now(),
    );

    final success = await provider.addStation(station);
    if (success && mounted) {
      _nameController.clear();
      _addressController.clear();
      _latController.clear();
      _lngController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station added successfully')),
      );
      // Refresh the stations list
      await provider.loadStations();
    } else if (mounted) {
      final errorMessage = provider.error ?? 'Failed to add station';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Station Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: AppDimensions.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Add Station'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<BusProvider>(
                builder: (context, provider, _) {
                  final stations = provider.stations;
                  if (stations.isEmpty) {
                    return const Center(child: Text('No stations'));
                  }
                  return ListView.separated(
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final s = stations[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(s.name),
                          subtitle: Text('${s.latitude}, ${s.longitude}\n${s.address}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}