
class BusModel {
  final String id;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final int capacity;
  final String status;
  final String routeId;
  final double? currentLatitude;
  final double? currentLongitude;
  final int? currentPassengers;
  final double? speed;
  final DateTime? lastUpdated;
  final String deviceId; // NodeMCU device identifier
  final bool emergencyAlert;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.capacity,
    required this.status,
    required this.routeId,
    required this.deviceId,
    this.currentLatitude,
    this.currentLongitude,
    this.currentPassengers,
    this.speed,
    this.lastUpdated,
    this.emergencyAlert = false,
  });

  factory BusModel.fromMap(Map<String, dynamic> map, String id) {
    return BusModel(
      id: id,
      busNumber: map['busNumber'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      capacity: map['capacity'] ?? 0,
      status: map['status'] ?? 'inactive',
      routeId: map['routeId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),
      currentPassengers: map['currentPassengers'],
      speed: map['speed']?.toDouble(),
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.parse(map['lastUpdated'])
          : null,
      emergencyAlert: map['emergencyAlert'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'capacity': capacity,
      'status': status,
      'routeId': routeId,
      'deviceId': deviceId,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'currentPassengers': currentPassengers,
      'speed': speed,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'emergencyAlert': emergencyAlert,
    };
  }

  BusModel copyWith({
    String? id,
    String? busNumber,
    String? driverName,
    String? driverPhone,
    int? capacity,
    String? status,
    String? routeId,
    String? deviceId,
    double? currentLatitude,
    double? currentLongitude,
    int? currentPassengers,
    double? speed,
    DateTime? lastUpdated,
    bool? emergencyAlert,
  }) {
    return BusModel(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      routeId: routeId ?? this.routeId,
      deviceId: deviceId ?? this.deviceId,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentPassengers: currentPassengers ?? this.currentPassengers,
      speed: speed ?? this.speed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      emergencyAlert: emergencyAlert ?? this.emergencyAlert,
    );
  }

  bool get hasLocation => currentLatitude != null && currentLongitude != null;
  
  bool get isActive => status == 'active';
  
  String get passengerInfo => currentPassengers != null 
      ? '$currentPassengers / $capacity passengers'
      : 'Capacity: $capacity';
}