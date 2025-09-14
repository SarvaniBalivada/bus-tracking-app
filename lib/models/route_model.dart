class RouteModel {
  final String id;
  final String name;
  final String description;
  final List<String> stationIds;
  final double distance;
  final bool isActive;
  final DateTime createdAt;

  RouteModel({
    required this.id,
    required this.name,
    required this.description,
    required this.stationIds,
    required this.distance,
    this.isActive = true,
    required this.createdAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      stationIds: List<String>.from(map['stationIds'] ?? []),
      distance: map['distance']?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'stationIds': stationIds,
      'distance': distance,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RouteModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? stationIds,
    double? distance,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stationIds: stationIds ?? this.stationIds,
      distance: distance ?? this.distance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}