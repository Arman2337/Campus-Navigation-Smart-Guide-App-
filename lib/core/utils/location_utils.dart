import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationUtils {
  /// Calculate distance in kilometers between two lat/lng points
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  /// Format distance for display (e.g., "250 m" or "1.2 km")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Format duration in seconds to readable string
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Get bearing between two points (in degrees)
  static double getBearing(LatLng from, LatLng to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Check if a user is within a given radius of a point
  static bool isWithinRadius(
    LatLng userPosition,
    LatLng targetPosition,
    double radiusMeters,
  ) {
    final distanceMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      targetPosition.latitude,
      targetPosition.longitude,
    );
    return distanceMeters <= radiusMeters;
  }

  /// Convert LatLng to a readable string
  static String latLngToString(LatLng latLng) {
    return '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
  }

  /// Sort locations by distance from a given point
  static List<T> sortByDistance<T>({
    required List<T> locations,
    required LatLng userPosition,
    required double Function(T) getLat,
    required double Function(T) getLng,
  }) {
    locations.sort((a, b) {
      final distA = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        getLat(a),
        getLng(a),
      );
      final distB = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        getLat(b),
        getLng(b),
      );
      return distA.compareTo(distB);
    });
    return locations;
  }

  /// Filter locations within a radius (in km)
  static List<T> filterByRadius<T>({
    required List<T> locations,
    required LatLng userPosition,
    required double radiusKm,
    required double Function(T) getLat,
    required double Function(T) getLng,
  }) {
    return locations.where((location) {
      final dist = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        getLat(location),
        getLng(location),
      );
      return dist <= radiusKm;
    }).toList();
  }
}
