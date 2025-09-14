import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/models/route_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';

class BusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _subscribedBusIds = <String>{};
  
  List<BusModel> _buses = [];
  List<StationModel> _stations = [];
  List<RouteModel> _routes = [];
  BusModel? _selectedBus;
  bool _isLoading = false;
  String? _error;

  List<BusModel> get buses => _buses;
  List<StationModel> get stations => _stations;
  List<RouteModel> get routes => _routes;
  BusModel? get selectedBus => _selectedBus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isSubscribed(String busId) => _subscribedBusIds.contains(busId);

  // Get active buses only
  List<BusModel> get activeBuses => _buses.where((bus) => bus.isActive).toList();
  
  // Get buses with current location
  List<BusModel> get busesWithLocation => _buses.where((bus) => bus.hasLocation).toList();

  Future<void> loadBuses() async {
    try {
      _setLoading(true);
      _error = null;

      QuerySnapshot snapshot = await _firestore
          .collection(AppStrings.busesCollection)
          .orderBy('busNumber')
          .get();

      _buses = snapshot.docs
          .map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // If no buses in Firestore, load demo data
      if (_buses.isEmpty) {
        _loadDemoBuses();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // On error, load demo data as fallback
      _loadDemoBuses();
      _setLoading(false);
      notifyListeners();
    }
  }

  void _loadDemoBuses() {
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
        busFare: 25.0,
        routeDescription: 'Vijaywada -> Bhimavaram -> Vizag', // Intermediate stations
        fromStationId: 'station1', // Will be mapped to actual station names
        toStationId: 'station2',
        departureTime: DateTime.now().add(const Duration(minutes: 10)),
        arrivalTime: DateTime.now().add(const Duration(hours: 1, minutes: 5)),
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
        busFare: 18.0,
        routeDescription: 'Hyderabad -> Warangal -> Karimnagar', // Intermediate stations
        fromStationId: 'station3',
        toStationId: 'station4',
        departureTime: DateTime.now().add(const Duration(minutes: 20)),
        arrivalTime: DateTime.now().add(const Duration(hours: 1, minutes: 20)),
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
        capacity: 45,
        status: BusStatus.emergency,
        routeId: 'route3',
        deviceId: 'ESP32_003',
        busFare: 30.0,
        routeDescription: 'Chennai -> Pondicherry -> Bangalore',
        fromStationId: 'station4',
        toStationId: 'station3',
        departureTime: DateTime.now().add(const Duration(minutes: 5)),
        arrivalTime: DateTime.now().add(const Duration(hours: 2)),
        currentLatitude: 13.0827,
        currentLongitude: 80.2707,
        currentPassengers: 35,
        speed: 0.0, // Stopped due to emergency
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 30)),
        emergencyAlert: true, // Emergency alert active
      ),
      BusModel(
        id: 'bus4',
        busNumber: 'BT004',
        driverName: 'Sarah Wilson',
        driverPhone: '+91 9876543213',
        capacity: 38,
        status: BusStatus.active,
        routeId: 'route4',
        deviceId: 'ESP32_004',
        busFare: 22.0,
        routeDescription: 'Pune -> Mumbai -> Surat',
        fromStationId: 'station5',
        toStationId: 'station6',
        departureTime: DateTime.now().add(const Duration(minutes: 15)),
        arrivalTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
        currentLatitude: 18.5204,
        currentLongitude: 73.8567,
        currentPassengers: 28,
        speed: 55.0,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
  }

  Future<void> loadStations() async {
    try {
      _setLoading(true);
      _error = null;

      QuerySnapshot snapshot = await _firestore
          .collection(AppStrings.stationsCollection)
          .get();

      _stations = snapshot.docs
          .map((doc) => StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((station) => station.isActive)
          .toList();

      // If no stations in Firestore, load demo data
      if (_stations.isEmpty) {
        _loadDemoStations();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load stations: ${e.toString()}';
      print('Firestore error loading stations: $e');
      // On error, load demo data as fallback
      _loadDemoStations();
      _setLoading(false);
      notifyListeners();
    }
  }

  void _loadDemoStations() {
    _stations = [
      StationModel(
        id: 'station1',
        name: 'Delhi',
        address: 'Delhi Bus Stand',
        latitude: 28.6139,
        longitude: 77.2090,
        routeIds: ['route1'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      StationModel(
        id: 'station2',
        name: 'Mumbai',
        address: 'Mumbai Bus Stand',
        latitude: 19.0760,
        longitude: 72.8777,
        routeIds: ['route1'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      StationModel(
        id: 'station3',
        name: 'Bangalore',
        address: 'Bangalore Bus Stand',
        latitude: 12.9716,
        longitude: 77.5946,
        routeIds: ['route2', 'route3'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      StationModel(
        id: 'station4',
        name: 'Chennai',
        address: 'Chennai Bus Stand',
        latitude: 13.0827,
        longitude: 80.2707,
        routeIds: ['route2', 'route3'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      StationModel(
        id: 'station5',
        name: 'Pune',
        address: 'Pune Bus Stand',
        latitude: 18.5204,
        longitude: 73.8567,
        routeIds: ['route4'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      StationModel(
        id: 'station6',
        name: 'Surat',
        address: 'Surat Bus Stand',
        latitude: 21.1702,
        longitude: 72.8311,
        routeIds: ['route4'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  Future<void> loadRoutes() async {
    try {
      _setLoading(true);
      _error = null;

      QuerySnapshot snapshot = await _firestore
          .collection(AppStrings.routesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _routes = snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // If no routes in Firestore, load demo data
      if (_routes.isEmpty) {
        _loadDemoRoutes();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // On error, load demo data as fallback
      _loadDemoRoutes();
      _setLoading(false);
      notifyListeners();
    }
  }

  void _loadDemoRoutes() {
    _routes = [
      RouteModel(
        id: 'route1',
        name: 'Delhi to Mumbai',
        description: 'Delhi to Mumbai via major highways',
        stationIds: ['station1', 'station2'],
        distance: 1400.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      RouteModel(
        id: 'route2',
        name: 'Bangalore to Chennai',
        description: 'Bangalore to Chennai via Hosur',
        stationIds: ['station3', 'station4'],
        distance: 350.0,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      RouteModel(
        id: 'route3',
        name: 'Chennai to Bangalore',
        description: 'Chennai to Bangalore via Pondicherry',
        stationIds: ['station4', 'station3'],
        distance: 350.0,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      RouteModel(
        id: 'route4',
        name: 'Pune to Surat',
        description: 'Pune to Surat via Mumbai',
        stationIds: ['station5', 'station6'],
        distance: 450.0,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  Future<bool> addBus(BusModel bus) async {
    try {
      _setLoading(true);
      _error = null;
      
      DocumentReference docRef = await _firestore
          .collection(AppStrings.busesCollection)
          .add(bus.toMap());
      
      BusModel newBus = bus.copyWith(id: docRef.id);
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
      
      await _firestore
          .collection(AppStrings.busesCollection)
          .doc(bus.id)
          .update(bus.toMap());
      
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
      
      await _firestore
          .collection(AppStrings.busesCollection)
          .doc(busId)
          .delete();
      
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

  Future<bool> addStation(StationModel station) async {
    try {
      _setLoading(true);
      _error = null;

      DocumentReference docRef = await _firestore
          .collection(AppStrings.stationsCollection)
          .add(station.toMap());

      StationModel newStation = station.copyWith(id: docRef.id);
      _stations.add(newStation);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save to database: ${e.toString()}';
      print('Firestore error adding station: $e');

      // Even if Firestore fails, add to local list so user can see it
      // Generate a temporary ID for local use
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      StationModel tempStation = station.copyWith(id: tempId);
      _stations.add(tempStation);

      _setLoading(false);
      notifyListeners();
      return true; // Return true so UI shows success
    }
  }

  Future<bool> updateStation(StationModel station) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _firestore
          .collection(AppStrings.stationsCollection)
          .doc(station.id)
          .update(station.toMap());
      
      int index = _stations.indexWhere((s) => s.id == station.id);
      if (index != -1) {
        _stations[index] = station;
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

  // Real-time bus tracking
  Stream<BusModel?> getBusLocationStream(String busId) {
    return _firestore
        .collection(AppStrings.busesCollection)
        .doc(busId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return BusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update bus real-time data (called by NodeMCU device)
  Future<void> updateBusRealTimeData({
    required String busId,
    required double latitude,
    required double longitude,
    required int passengerCount,
    required double speed,
    bool emergencyAlert = false,
  }) async {
    try {
      await _firestore
          .collection(AppStrings.busesCollection)
          .doc(busId)
          .update({
        'currentLatitude': latitude,
        'currentLongitude': longitude,
        'currentPassengers': passengerCount,
        'speed': speed,
        'lastUpdated': Timestamp.now(),
        'emergencyAlert': emergencyAlert,
        'status': emergencyAlert ? BusStatus.emergency : BusStatus.active,
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectBus(BusModel? bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  void toggleSubscription(String busId) {
    if (_subscribedBusIds.contains(busId)) {
      _subscribedBusIds.remove(busId);
    } else {
      _subscribedBusIds.add(busId);
    }
    notifyListeners();
  }

  /// Trigger emergency alert for a specific bus
  Future<bool> triggerEmergencyAlert(String busId, {String? reason}) async {
    try {
      _setLoading(true);

      final bus = _buses.firstWhere((b) => b.id == busId, orElse: () => BusModel(id: '', busNumber: '', driverName: '', driverPhone: '', capacity: 0, status: '', routeId: '', deviceId: '', busFare: 0.0, routeDescription: ''));

      if (bus.id.isEmpty) {
        _setLoading(false);
        return false;
      }

      // Update bus with emergency alert
      final success = await updateBus(
        bus.copyWith(
          emergencyAlert: true,
          status: 'emergency',
          speed: 0.0, // Stop the bus
        ),
      );

      _setLoading(false);
      return success;
    } catch (e) {
      _error = 'Failed to trigger emergency alert: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Clear emergency alert for a specific bus
  Future<bool> clearEmergencyAlert(String busId) async {
    try {
      _setLoading(true);

      final bus = _buses.firstWhere((b) => b.id == busId, orElse: () => BusModel(id: '', busNumber: '', driverName: '', driverPhone: '', capacity: 0, status: '', routeId: '', deviceId: '', busFare: 0.0, routeDescription: ''));

      if (bus.id.isEmpty) {
        _setLoading(false);
        return false;
      }

      // Update bus to clear emergency alert
      final success = await updateBus(
        bus.copyWith(
          emergencyAlert: false,
          status: 'active',
        ),
      );

      _setLoading(false);
      return success;
    } catch (e) {
      _error = 'Failed to clear emergency alert: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Get all buses with emergency alerts
  List<BusModel> get emergencyBuses => _buses.where((bus) => bus.emergencyAlert).toList();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 🔹 Search buses that run from [sourceName] to [destinationName]
  List<BusModel> searchBuses(String sourceName, String destinationName) {
    return _buses.where((bus) {
      if (!bus.isActive) return false;

      // Get station names from the bus's from/to station IDs
      final busSourceName = getStationName(bus.fromStationId ?? '');
      final busDestName = getStationName(bus.toStationId ?? '');

      // 1. Check exact match (original logic)
      final exactSourceMatch = busSourceName.toLowerCase() == sourceName.toLowerCase();
      final exactDestMatch = busDestName.toLowerCase() == destinationName.toLowerCase();
      if (exactSourceMatch && exactDestMatch) return true;

      // 2. Check if searched route is a segment of the bus's complete route
      final completeRoute = _buildCompleteRoute(bus);
      return _isRouteSegmentInCompleteRoute(sourceName, destinationName, completeRoute);
    }).toList();
  }

  /// Build complete route including from, intermediate, and to stations
  List<String> _buildCompleteRoute(BusModel bus) {
    final route = <String>[];

    // Add from station
    final fromStation = getStationName(bus.fromStationId ?? '');
    if (fromStation.isNotEmpty) route.add(fromStation);

    // Add intermediate stations from route description
    final intermediateStations = _parseIntermediateStations(bus.routeDescription);
    route.addAll(intermediateStations);

    // Add to station
    final toStation = getStationName(bus.toStationId ?? '');
    if (toStation.isNotEmpty) route.add(toStation);

    return route;
  }

  /// Parse intermediate stations from route description
  List<String> _parseIntermediateStations(String routeDesc) {
    if (routeDesc.contains('->')) {
      final parts = routeDesc.split('->').map((s) => s.trim()).toList();
      return parts.where((part) => part.isNotEmpty).toList();
    }

    if (routeDesc.contains(',')) {
      final parts = routeDesc.split(',').map((s) => s.trim()).toList();
      return parts.where((part) => part.isNotEmpty).toList();
    }

    if (routeDesc.contains('↔')) {
      final parts = routeDesc.split('↔').map((s) => s.trim()).toList();
      return parts.where((part) => part.isNotEmpty).toList();
    }

    return [];
  }

  /// Check if searched route segment exists in complete route
  bool _isRouteSegmentInCompleteRoute(String sourceName, String destName, List<String> completeRoute) {
    // Convert to lowercase for case-insensitive matching
    final source = sourceName.toLowerCase();
    final dest = destName.toLowerCase();
    final route = completeRoute.map((s) => s.toLowerCase()).toList();

    // Find indices of source and destination in the complete route
    final sourceIndex = route.indexOf(source);
    final destIndex = route.indexOf(dest);

    // Both stations must exist in the route and source must come before destination
    return sourceIndex != -1 && destIndex != -1 && sourceIndex < destIndex;
  }

  /// Helper to get route for a bus
  RouteModel? getRouteForBus(String busId) {
    final bus = _buses.firstWhere((b) => b.id == busId, orElse: () => BusModel(id: '', busNumber: '', driverName: '', driverPhone: '', capacity: 0, status: '', routeId: '', deviceId: '', busFare: 0.0, routeDescription: ''));
    if (bus.id.isEmpty) return null;
    return _routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', name: '', description: '', stationIds: [], distance: 0.0, createdAt: DateTime.now()));
  }

  /// Helper to get station name
  String getStationName(String stationId) {
    return _stations.firstWhere((s) => s.id == stationId, orElse: () => StationModel(id: '', name: '', address: '', latitude: 0.0, longitude: 0.0, routeIds: [], createdAt: DateTime.now())).name;
  }
}