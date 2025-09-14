import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busIdController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _capacityController = TextEditingController();
  final _routeIdController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _busFareController = TextEditingController();
  final _routeDescriptionController = TextEditingController();
  final _fromStationController = TextEditingController();
  final _toStationController = TextEditingController();
  String _status = BusStatus.active;
  BusModel? _editingBus;
  bool _isEditing = false;

  @override
  void dispose() {
    _busIdController.dispose();
    _busNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _capacityController.dispose();
    _routeIdController.dispose();
    _deviceIdController.dispose();
    _busFareController.dispose();
    _routeDescriptionController.dispose();
    _fromStationController.dispose();
    _toStationController.dispose();
    super.dispose();
  }

  void _addBus() {
    if (_formKey.currentState!.validate()) {
      final bus = BusModel(
        id: _busIdController.text,
        busNumber: _busNumberController.text,
        driverName: _driverNameController.text,
        driverPhone: _driverPhoneController.text,
        capacity: int.parse(_capacityController.text),
        status: _status,
        routeId: _routeIdController.text,
        deviceId: _deviceIdController.text,
        busFare: double.parse(_busFareController.text),
        routeDescription: _routeDescriptionController.text,
        fromStationId: _fromStationController.text,
        toStationId: _toStationController.text,
        currentLatitude: null,
        currentLongitude: null,
        emergencyAlert: false,
      );
      Provider.of<BusProvider>(context, listen: false).addBus(bus);
      Fluttertoast.showToast(msg: 'Bus added successfully');
      _clearForm();
    }
  }

  void _updateBus() {
    if (_formKey.currentState!.validate() && _editingBus != null) {
      final updatedBus = _editingBus!.copyWith(
        busNumber: _busNumberController.text,
        driverName: _driverNameController.text,
        driverPhone: _driverPhoneController.text,
        capacity: int.parse(_capacityController.text),
        status: _status,
        routeId: _routeIdController.text,
        deviceId: _deviceIdController.text,
        busFare: double.parse(_busFareController.text),
        routeDescription: _routeDescriptionController.text,
        fromStationId: _fromStationController.text,
        toStationId: _toStationController.text,
      );
      Provider.of<BusProvider>(context, listen: false).updateBus(updatedBus);
      Fluttertoast.showToast(msg: 'Bus updated successfully');
      _clearForm();
      setState(() {
        _editingBus = null;
        _isEditing = false;
      });
    }
  }

  void _editBus(BusModel bus) {
    setState(() {
      _editingBus = bus;
      _isEditing = true;
    });

    _busIdController.text = bus.id;
    _busNumberController.text = bus.busNumber;
    _driverNameController.text = bus.driverName;
    _driverPhoneController.text = bus.driverPhone;
    _capacityController.text = bus.capacity.toString();
    _routeIdController.text = bus.routeId;
    _deviceIdController.text = bus.deviceId;
    _busFareController.text = bus.busFare.toString();
    _routeDescriptionController.text = bus.routeDescription;
    _fromStationController.text = bus.fromStationId ?? '';
    _toStationController.text = bus.toStationId ?? '';
    _status = bus.status;
  }

  void _clearForm() {
    _busIdController.clear();
    _busNumberController.clear();
    _driverNameController.clear();
    _driverPhoneController.clear();
    _capacityController.clear();
    _routeIdController.clear();
    _deviceIdController.clear();
    _busFareController.clear();
    _routeDescriptionController.clear();
    _fromStationController.clear();
    _toStationController.clear();
    setState(() {
      _status = BusStatus.active;
      _editingBus = null;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboard),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Bus' : 'Add New Bus',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.margin),
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
                              controller: _busIdController,
                              decoration: const InputDecoration(labelText: 'Bus ID'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a bus ID';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _busNumberController,
                              decoration: const InputDecoration(labelText: 'Bus Number'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a bus number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _driverNameController,
                              decoration: const InputDecoration(labelText: 'Driver Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a driver name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _driverPhoneController,
                              decoration: const InputDecoration(labelText: 'Driver Phone'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a driver phone';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(labelText: 'Capacity'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter capacity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _busFareController,
                              decoration: const InputDecoration(labelText: 'Bus Fare'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a bus fare';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _routeIdController,
                              decoration: const InputDecoration(labelText: 'Route ID'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a route ID';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _deviceIdController,
                              decoration: const InputDecoration(labelText: 'Device ID'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a device ID';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _routeDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Route Description',
                              hintText: 'Example: Bhimavaram -> Vizag -> Tekkali',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a route description';
                              }
                              if (!value.contains('->')) {
                                return 'Please use "->" to separate intermediate stations';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📝 Route Description Guide:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Only intermediate stations: Station A -> Station B -> Station C',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Example: "Bhimavaram -> Vizag -> Tekkali"',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• From/To stations come from the station fields above',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Timeline will show: From → Intermediates → To',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fromStationController,
                              decoration: const InputDecoration(labelText: 'From Station'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter from station';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _toStationController,
                              decoration: const InputDecoration(labelText: 'To Station'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter to station';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        items: [
                          BusStatus.active,
                          BusStatus.inactive,
                          BusStatus.maintenance,
                          BusStatus.emergency,
                        ].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value ?? BusStatus.active;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                      const SizedBox(height: AppDimensions.margin),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isEditing ? _updateBus : _addBus,
                              child: Text(_isEditing ? 'Update Bus' : 'Add Bus'),
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearForm,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.margin),
            const Text(
              'Existing Buses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.margin),
            SizedBox(
              height: 400, // Fixed height for the list
              child: ListView.builder(
                itemCount: busProvider.buses.length,
                itemBuilder: (context, index) {
                  final bus = busProvider.buses[index];

                  // Get station names from IDs
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
                      title: Text('${fromStation.name} → ${toStation.name}'),
                      subtitle: Text(
                        [
                          'Bus: ${bus.busNumber}',
                          'Route: ${bus.routeDescription}',
                          'Status: ${bus.status}',
                          'Fare: ₹${bus.busFare.toStringAsFixed(0)}',
                          'Capacity: ${bus.capacity}',
                        ].join(' • '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit Bus',
                            onPressed: () => _editBus(bus),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Bus',
                            onPressed: () {
                              busProvider.deleteBus(bus.id);
                              Fluttertoast.showToast(msg: 'Bus removed');
                            },
                          ),
                        ],
                      ),
                    ),
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