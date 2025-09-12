import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/demo_bus_provider.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BusManagementScreen extends StatefulWidget {
  const BusManagementScreen({super.key});

  @override
  State<BusManagementScreen> createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _capacityController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _routeIdController = TextEditingController();
  
  String _selectedStatus = BusStatus.inactive;
  BusModel? _editingBus;

  @override
  void dispose() {
    _busNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _capacityController.dispose();
    _deviceIdController.dispose();
    _routeIdController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _busNumberController.clear();
    _driverNameController.clear();
    _driverPhoneController.clear();
    _capacityController.clear();
    _deviceIdController.clear();
    _routeIdController.clear();
    _selectedStatus = BusStatus.inactive;
    _editingBus = null;
  }

  void _editBus(BusModel bus) {
    setState(() {
      _editingBus = bus;
      _busNumberController.text = bus.busNumber;
      _driverNameController.text = bus.driverName;
      _driverPhoneController.text = bus.driverPhone;
      _capacityController.text = bus.capacity.toString();
      _deviceIdController.text = bus.deviceId;
      _routeIdController.text = bus.routeId;
      _selectedStatus = bus.status;
    });
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    final busProvider = Provider.of<DemoBusProvider>(context, listen: false);
    
    final bus = BusModel(
      id: _editingBus?.id ?? '',
      busNumber: _busNumberController.text.trim(),
      driverName: _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim(),
      capacity: int.parse(_capacityController.text),
      status: _selectedStatus,
      routeId: _routeIdController.text.trim(),
      deviceId: _deviceIdController.text.trim(),
    );

    bool success;
    if (_editingBus != null) {
      success = await busProvider.updateBus(bus);
    } else {
      success = await busProvider.addBus(bus);
    }

    if (success) {
      Fluttertoast.showToast(
        msg: _editingBus != null ? 'Bus updated successfully!' : 'Bus added successfully!',
      );
      _clearForm();
    } else {
      Fluttertoast.showToast(
        msg: busProvider.error ?? 'Failed to save bus',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DemoBusProvider>(context, listen: false).loadBuses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bus Form
          Card(
            margin: const EdgeInsets.all(AppDimensions.margin),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      _editingBus != null ? 'Edit Bus' : 'Add New Bus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _busNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Bus Number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter bus number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter capacity';
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
                            decoration: const InputDecoration(
                              labelText: 'Driver Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter driver name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _driverPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Driver Phone',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter driver phone';
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
                            controller: _deviceIdController,
                            decoration: const InputDecoration(
                              labelText: 'Device ID (NodeMCU)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter device ID';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _routeIdController,
                            decoration: const InputDecoration(
                              labelText: 'Route ID',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter route ID';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: BusStatus.active,
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: BusStatus.inactive,
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: BusStatus.maintenance,
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveBus,
                            child: Text(_editingBus != null ? 'Update Bus' : 'Add Bus'),
                          ),
                        ),
                        if (_editingBus != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _clearForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bus List
          Expanded(
            child: Consumer<DemoBusProvider>(
              builder: (context, busProvider, child) {
                if (busProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (busProvider.buses.isEmpty) {
                  return const Center(child: Text('No buses found'));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  itemCount: busProvider.buses.length,
                  itemBuilder: (context, index) {
                    final bus = busProvider.buses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bus.status == BusStatus.active
                              ? AppColors.success
                              : bus.status == BusStatus.maintenance
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                          child: const Icon(Icons.directions_bus, color: Colors.white),
                        ),
                        title: Text('Bus ${bus.busNumber}'),
                        subtitle: Text('${bus.driverName} • ${bus.passengerInfo}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => _editBus(bus),
                              child: const ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Bus'),
                                    content: Text('Are you sure you want to delete Bus ${bus.busNumber}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  final success = await busProvider.deleteBus(bus.id);
                                  if (success) {
                                    Fluttertoast.showToast(msg: 'Bus deleted successfully');
                                  }
                                }
                              },
                              child: const ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}