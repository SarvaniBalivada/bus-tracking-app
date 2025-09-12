class StationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> routeIds;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  StationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.routeIds,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  factory StationModel.fromMap(Map<String, dynamic> map, String id) {
    return StationModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      routeIds: List<String>.from(map['routeIds'] ?? []),
      description: map['description'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'routeIds': routeIds,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  StationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? routeIds,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      routeIds: routeIds ?? this.routeIds,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}