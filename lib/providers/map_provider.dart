import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/utils/location_utils.dart';
import '../core/utils/permission_handler.dart';
import '../core/constants/app_colors.dart';
import '../models/location_model.dart';

class MapProvider extends ChangeNotifier {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  LocationModel? _selectedLocation;
  StreamSubscription<Position>? _positionStream;
  bool _isLoadingPosition = false;

  GoogleMapController? get mapController => _mapController;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  LatLng? get currentPosition => _currentPosition;
  LocationModel? get selectedLocation => _selectedLocation;
  bool get isLoadingPosition => _isLoadingPosition;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> initializeUserLocation(BuildContext context) async {
    _isLoadingPosition = true;
    notifyListeners();

    try {
      final hasPermission =
          await AppPermissionHandler.requestLocationPermission(context);
      if (!hasPermission) {
        _isLoadingPosition = false;
        notifyListeners();
        return;
      }

      final serviceEnabled =
          await AppPermissionHandler.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await AppPermissionHandler.showEnableLocationDialog(context);
        }
        _isLoadingPosition = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoadingPosition = false;
      notifyListeners();

      _startLocationTracking();
    } catch (e) {
      _isLoadingPosition = false;
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
    });
  }

  void buildMarkers(List<LocationModel> locations, {Function(LocationModel)? onTap}) {
    _markers = locations.map((location) {
      final color = AppColors.getCategoryColor(location.category);
      return Marker(
        markerId: MarkerId(location.id),
        position: location.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _colorToHue(color),
        ),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: '${location.building} • ${location.floorLabel}',
        ),
        onTap: () {
          _selectedLocation = location;
          notifyListeners();
          onTap?.call(location);
        },
      );
    }).toSet();

    // Add user location marker if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
          zIndex: 2,
        ),
      );
    }

    notifyListeners();
  }

  void setPolyline(List<LatLng> polylineCoords, {Color color = AppColors.primary}) {
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoords,
        color: color,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
    notifyListeners();
  }

  void clearRoute() {
    _polylines = {};
    _selectedLocation = null;
    notifyListeners();
  }

  void selectLocation(LocationModel location) {
    _selectedLocation = location;
    animateToLocation(location.latLng);
    notifyListeners();
  }

  void clearSelection() {
    _selectedLocation = null;
    notifyListeners();
  }

  void animateToLocation(LatLng position, {double zoom = 17.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  void animateToCurrentLocation() {
    if (_currentPosition != null) {
      animateToLocation(_currentPosition!);
    }
  }

  double _colorToHue(Color color) {
    final hsv = HSVColor.fromColor(color);
    return hsv.hue;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
