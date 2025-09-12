import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracking_app/models/bus_model.dart';
import 'package:bus_tracking_app/models/station_model.dart';
import 'package:bus_tracking_app/utils/constants.dart';

class BusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
      
      QuerySnapshot snapshot = await _firestore
          .collection(AppStrings.busesCollection)
          .orderBy('busNumber')
          .get();
      
      _buses = snapshot.docs
          .map((doc) => BusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
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
      
      QuerySnapshot snapshot = await _firestore
          .collection(AppStrings.stationsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      _stations = snapshot.docs
          .map((doc) => StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
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
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}