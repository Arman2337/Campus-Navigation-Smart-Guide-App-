import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/services/directions_service.dart';
import '../core/services/tts_service.dart';
import '../core/utils/location_utils.dart';
import '../models/direction_model.dart';
import '../models/location_model.dart';

class NavigationProvider extends ChangeNotifier {
  final DirectionsService _directionsService = DirectionsService();
  final TtsService _ttsService = TtsService();

  DirectionModel? _currentDirections;
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _isMuted = false;
  bool _isLoading = false;
  String? _error;
  LocationModel? _destination;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _polylineCoords = [];

  DirectionModel? get currentDirections => _currentDirections;
  int get currentStepIndex => _currentStepIndex;
  bool get isNavigating => _isNavigating;
  bool get isMuted => _isMuted;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LocationModel? get destination => _destination;
  List<LatLng> get polylineCoords => _polylineCoords;

  DirectionStep? get currentStep {
    if (_currentDirections == null ||
        _currentStepIndex >= _currentDirections!.steps.length) return null;
    return _currentDirections!.steps[_currentStepIndex];
  }

  Future<void> startNavigation({
    required LatLng origin,
    required LocationModel destination,
    String mode = 'walking',
  }) async {
    _isLoading = true;
    _error = null;
    _destination = destination;
    _currentStepIndex = 0;
    notifyListeners();

    try {
      await _ttsService.initialize();
      _currentDirections = await _directionsService.getDirections(
        origin: origin,
        destination: destination.latLng,
        mode: mode,
      );

      _polylineCoords = _currentDirections!.polylineCoords;
      _isNavigating = true;
      _isLoading = false;
      notifyListeners();

      // Speak start announcement
      if (!_isMuted) {
        await _ttsService.speak(
          'Starting navigation to ${destination.name}. '
          'Total distance: ${_currentDirections!.distanceText}. '
          'Estimated time: ${_currentDirections!.durationText}.',
        );
      }

      _startPositionWatcher();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isNavigating = false;
      notifyListeners();
    }
  }

  void _startPositionWatcher() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _checkStepProgress(LatLng(position.latitude, position.longitude));
    });
  }

  void _checkStepProgress(LatLng userPosition) {
    if (_currentDirections == null || !_isNavigating) return;
    final steps = _currentDirections!.steps;
    if (_currentStepIndex >= steps.length) return;

    final step = steps[_currentStepIndex];
    final isNear = LocationUtils.isWithinRadius(
      userPosition,
      step.endLocation,
      20.0, // 20 meters
    );

    if (isNear) {
      _currentStepIndex++;
      notifyListeners();

      if (_currentStepIndex < steps.length) {
        final nextStep = steps[_currentStepIndex];
        if (!_isMuted) {
          _ttsService.speak(nextStep.instruction);
        }
      } else {
        // Arrived
        if (!_isMuted) {
          _ttsService.speak('You have arrived at ${_destination?.name ?? 'your destination'}.');
        }
        endNavigation();
      }
    }

    // Check if user has deviated more than 50m from current step
    final distanceFromStep = LocationUtils.calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      step.startLocation.latitude,
      step.startLocation.longitude,
    ) * 1000; // Convert to meters

    if (distanceFromStep > 200) {
      // Could trigger re-routing here
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentDirections == null) return;
    if (_currentStepIndex < _currentDirections!.steps.length - 1) {
      _currentStepIndex++;
      notifyListeners();
      final step = _currentDirections!.steps[_currentStepIndex];
      if (!_isMuted) {
        _ttsService.speak(step.instruction);
      }
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _ttsService.setMuted(_isMuted);
    notifyListeners();
  }

  void endNavigation() {
    _isNavigating = false;
    _currentDirections = null;
    _currentStepIndex = 0;
    _destination = null;
    _polylineCoords = [];
    _positionStream?.cancel();
    _ttsService.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _ttsService.dispose();
    super.dispose();
  }
}
