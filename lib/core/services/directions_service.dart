import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../models/direction_model.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  // Replace with your actual key or load from environment
  static const String _apiKey = 'AIzaSyDh7x404u49Qqrymcsrtoq7qQ8DTUF0n1A';

  final PolylinePoints _polylinePoints = PolylinePoints();

  /// Get directions between origin and destination
  Future<DirectionModel> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking',
  }) async {
    final url = Uri.parse(
      '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String;

    if (status != 'OK') {
      throw Exception('Directions API error: $status');
    }

    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes[0] as Map<String, dynamic>;
    final legs = route['legs'] as List;
    final leg = legs[0] as Map<String, dynamic>;

    // Parse steps
    final rawSteps = leg['steps'] as List;
    final steps = rawSteps.map<DirectionStep>((step) {
      final stepMap = step as Map<String, dynamic>;
      final startLoc = stepMap['start_location'] as Map<String, dynamic>;
      final endLoc = stepMap['end_location'] as Map<String, dynamic>;
      return DirectionStep(
        instruction: _stripHtml(stepMap['html_instructions'] as String),
        distance: (stepMap['distance'] as Map)['text'] as String,
        duration: (stepMap['duration'] as Map)['text'] as String,
        maneuver: stepMap['maneuver'] as String? ?? '',
        startLocation: LatLng(
          startLoc['lat'] as double,
          startLoc['lng'] as double,
        ),
        endLocation: LatLng(
          endLoc['lat'] as double,
          endLoc['lng'] as double,
        ),
        polyline: stepMap['polyline']['points'] as String,
      );
    }).toList();

    // Decode overall polyline
    final overviewPolyline =
        route['overview_polyline']['points'] as String;
    final decodedPoints = _polylinePoints.decodePolyline(overviewPolyline);
    final polylineCoords = decodedPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final distanceText = (leg['distance'] as Map)['text'] as String;
    final distanceValue = (leg['distance'] as Map)['value'] as int;
    final durationText = (leg['duration'] as Map)['text'] as String;
    final durationValue = (leg['duration'] as Map)['value'] as int;

    // Start/end addresses
    final startAddress = leg['start_address'] as String;
    final endAddress = leg['end_address'] as String;

    return DirectionModel(
      steps: steps,
      polylineCoords: polylineCoords,
      distanceText: distanceText,
      distanceValue: distanceValue,
      durationText: durationText,
      durationValue: durationValue,
      startAddress: startAddress,
      endAddress: endAddress,
    );
  }

  /// Strip HTML tags from instruction text
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
