import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final String id;
  final String name;
  final String category;
  final String building;
  final int floor;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<String> tags;
  final bool isIndoor;
  final String? indoorFloorPlanUrl;
  final DateTime? createdAt;

  const LocationModel({
    required this.id,
    required this.name,
    required this.category,
    required this.building,
    required this.floor,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl = '',
    this.tags = const [],
    this.isIndoor = false,
    this.indoorFloorPlanUrl,
    this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      building: map['building'] as String? ?? '',
      floor: (map['floor'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isIndoor: map['isIndoor'] as bool? ?? false,
      indoorFloorPlanUrl: map['indoorFloorPlanUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'building': building,
      'floor': floor,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'tags': tags,
      'isIndoor': isIndoor,
      'indoorFloorPlanUrl': indoorFloorPlanUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  LocationModel copyWith({
    String? id,
    String? name,
    String? category,
    String? building,
    int? floor,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? tags,
    bool? isIndoor,
    String? indoorFloorPlanUrl,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isIndoor: isIndoor ?? this.isIndoor,
      indoorFloorPlanUrl: indoorFloorPlanUrl ?? this.indoorFloorPlanUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get floorLabel {
    if (floor == 0) return 'Ground Floor';
    if (floor == 1) return '1st Floor';
    if (floor == 2) return '2nd Floor';
    if (floor == 3) return '3rd Floor';
    return '${floor}th Floor';
  }
}
