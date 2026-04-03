import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionModel {
  final List<DirectionStep> steps;
  final List<LatLng> polylineCoords;
  final String distanceText;
  final int distanceValue; // meters
  final String durationText;
  final int durationValue; // seconds
  final String startAddress;
  final String endAddress;

  const DirectionModel({
    required this.steps,
    required this.polylineCoords,
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationValue,
    required this.startAddress,
    required this.endAddress,
  });

  int get totalSteps => steps.length;
}

class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;
  final LatLng startLocation;
  final LatLng endLocation;
  final String polyline;

  const DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
  });

  /// Get the appropriate icon name for the maneuver
  String get maneuverIcon {
    switch (maneuver) {
      case 'turn-left':
        return 'turn_left';
      case 'turn-right':
        return 'turn_right';
      case 'turn-slight-left':
        return 'turn_slight_left';
      case 'turn-slight-right':
        return 'turn_slight_right';
      case 'turn-sharp-left':
        return 'turn_sharp_left';
      case 'turn-sharp-right':
        return 'turn_sharp_right';
      case 'uturn-left':
      case 'uturn-right':
        return 'u_turn_left';
      case 'roundabout-left':
      case 'roundabout-right':
        return 'roundabout_left';
      case 'ramp-left':
      case 'ramp-right':
        return 'ramp_left';
      case 'merge':
        return 'merge';
      case 'fork-left':
      case 'fork-right':
        return 'fork_right';
      case 'ferry':
        return 'directions_boat';
      case 'ferry-train':
        return 'train';
      default:
        return 'straight';
    }
  }
}
