import 'package:flutter/material.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';

class DemoBusProvider extends ChangeNotifier {
  List<BusModel> _buses = [];
  List<StationModel> _stations = [];
  BusModel? _selectedBus;
  bool _isLoading = false;
  String? _error;

  List<BusModel> get buses => _buses;
  List<StationModel> get stations => _stations;
  BusModel? get selectedBus => _selectedBus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get active buses only
  List<BusModel> get activeBuses => _buses.where((bus) => bus.isActive).toList();
  
  // Get buses with current location
  List<BusModel> get busesWithLocation => _buses.where((bus) => bus.hasLocation).toList();

  Future<void> loadBuses() async {
    try {
      _setLoading(true);
      _error = null;
      
      // Demo data - in real app this would be from Firestore
      await Future.delayed(const Duration(seconds: 1));
      
      _buses = [
        BusModel(
          id: 'bus1',
          busNumber: 'BT001',
          driverName: 'John Doe',
          driverPhone: '+91 9876543210',
          capacity: 40,
          status: BusStatus.active,
          routeId: 'route1',
          deviceId: 'ESP32_001',
          currentLatitude: 28.6139,
          currentLongitude: 77.2090,
          currentPassengers: 25,
          speed: 35.5,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        BusModel(
          id: 'bus2',
          busNumber: 'BT002',
          driverName: 'Jane Smith',
          driverPhone: '+91 9876543211',
          capacity: 35,
          status: BusStatus.active,
          routeId: 'route2',
          deviceId: 'ESP32_002',
          currentLatitude: 28.6129,
          currentLongitude: 77.2295,
          currentPassengers: 18,
          speed: 42.0,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        BusModel(
          id: 'bus3',
          busNumber: 'BT003',
          driverName: 'Mike Johnson',
          driverPhone: '+91 9876543212',
          capacity: 50,
          status: BusStatus.maintenance,
          routeId: 'route3',
          deviceId: 'ESP32_003',
        ),
      ];
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> loadStations() async {
    try {
      _setLoading(true);
      _error = null;
      
      // Demo data
      await Future.delayed(const Duration(milliseconds: 500));
      
      _stations = [
        StationModel(
          id: 'station1',
          name: 'Central Bus Station',
          address: 'Connaught Place, New Delhi',
          latitude: 28.6304,
          longitude: 77.2177,
          routeIds: ['route1', 'route2'],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        StationModel(
          id: 'station2',
          name: 'Airport Terminal',
          address: 'IGI Airport, New Delhi',
          latitude: 28.5562,
          longitude: 77.1000,
          routeIds: ['route1'],
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        StationModel(
          id: 'station3',
          name: 'Railway Station',
          address: 'New Delhi Railway Station',
          latitude: 28.6431,
          longitude: 77.2197,
          routeIds: ['route2', 'route3'],
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ];
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> addBus(BusModel bus) async {
    try {
      _setLoading(true);
      _error = null;
      
      await Future.delayed(const Duration(seconds: 1));
      
      BusModel newBus = bus.copyWith(
        id: 'bus_${DateTime.now().millisecondsSinceEpoch}',
      );
      _buses.add(newBus);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBus(BusModel bus) async {
    try {
      _setLoading(true);
      _error = null;
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      int index = _buses.indexWhere((b) => b.id == bus.id);
      if (index != -1) {
        _buses[index] = bus;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBus(String busId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _buses.removeWhere((bus) => bus.id == busId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void selectBus(BusModel? bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}